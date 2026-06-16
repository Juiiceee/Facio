import CoreGraphics
import Foundation

/// Transforme un PDF produit par CoreGraphics en conteneur **Factur-X / PDF/A-3** :
/// embarque `factur-x.xml` comme fichier associé (`/AF` + `/Names/EmbeddedFiles`),
/// ajoute les métadonnées XMP Factur-X et un `OutputIntent` sRGB.
///
/// Technique : **mise à jour incrémentale** — les octets du PDF d'origine sont
/// conservés tels quels, et de nouveaux objets + une nouvelle section `xref` +
/// un `trailer` avec `/Prev` sont ajoutés à la fin. CoreGraphics émet une table
/// xref classique (vérifié sur macOS 15), ce qui rend cette approche fiable.
///
/// ⚠️ Conformité : ceci produit un PDF *structuré* Factur-X (XML correct et
/// atteignable). La conformité PDF/A-3B stricte (polices entièrement embarquées,
/// etc.) n'est pas garantie pour une sortie CoreGraphics brute et devra être
/// validée (veraPDF) avant d'être revendiquée. Voir issue #92.
enum FacturXPDFWriter {
    static let attachmentFilename = "factur-x.xml"

    /// Embarque le XML dans le PDF. Retourne `nil` si le PDF d'origine n'a pas
    /// la structure attendue (l'appelant retombe alors sur le PDF simple).
    static func embed(xml: String, into pdf: Data, invoiceNumber: String, modDate: Date) -> Data? {
        guard !pdf.isEmpty,
              let meta = parseTrailer(in: pdf) else { return nil }

        let xmlBytes = Data(xml.utf8)
        let xmp = Data(xmpPacket(invoiceNumber: invoiceNumber).utf8)
        let icc = srgbICCData()

        // Numéros d'objets : les nouveaux commencent à /Size ; le catalogue est
        // ré-émis sous son numéro existant.
        let xmlObj = meta.size
        let filespecObj = meta.size + 1
        let metaObj = meta.size + 2
        // OutputIntent + ICC seulement si le profil sRGB est disponible.
        let outputIntentObj = meta.size + 3
        let iccObj = meta.size + 4
        let newSize = icc != nil ? meta.size + 5 : meta.size + 3

        var out = pdf
        var offsets: [(obj: Int, offset: Int)] = []

        func appendObject(_ number: Int, _ body: Data) {
            out.append(0x0A) // séparateur \n
            offsets.append((number, out.count))
            out.append(Data("\(number) 0 obj\n".utf8))
            out.append(body)
            out.append(Data("\nendobj".utf8))
        }

        // 1. Flux du fichier embarqué (XML)
        var xmlStream = Data("<< /Type /EmbeddedFile /Subtype /text#2Fxml /Params << /ModDate (D:\(pdfDate(modDate))) /Size \(xmlBytes.count) >> /Length \(xmlBytes.count) >>\nstream\n".utf8)
        xmlStream.append(xmlBytes)
        xmlStream.append(Data("\nendstream".utf8))
        appendObject(xmlObj, xmlStream)

        // 2. Spécification de fichier (filespec)
        appendObject(filespecObj, Data("""
        << /Type /Filespec /F (\(attachmentFilename)) /UF (\(attachmentFilename)) /AFRelationship /Data /Desc (Factur-X XML invoice) /EF << /F \(xmlObj) 0 R /UF \(xmlObj) 0 R >> >>
        """.utf8))

        // 3. Métadonnées XMP du document
        var xmpStream = Data("<< /Type /Metadata /Subtype /XML /Length \(xmp.count) >>\nstream\n".utf8)
        xmpStream.append(xmp)
        xmpStream.append(Data("\nendstream".utf8))
        appendObject(metaObj, xmpStream)

        // 4. OutputIntent + profil ICC sRGB (PDF/A)
        if let icc {
            appendObject(outputIntentObj, Data("""
            << /Type /OutputIntent /S /GTS_PDFA1 /OutputConditionIdentifier (sRGB IEC61966-2.1) /Info (sRGB IEC61966-2.1) /DestOutputProfile \(iccObj) 0 R >>
            """.utf8))
            var iccStream = Data("<< /N 3 /Length \(icc.count) >>\nstream\n".utf8)
            iccStream.append(icc)
            iccStream.append(Data("\nendstream".utf8))
            appendObject(iccObj, iccStream)
        }

        // 5. Catalogue ré-émis (même numéro d'objet) avec les ajouts Factur-X
        var catalogExtras = " /AF [ \(filespecObj) 0 R ]"
            + " /Names << /EmbeddedFiles << /Names [ (\(attachmentFilename)) \(filespecObj) 0 R ] >> >>"
            + " /Metadata \(metaObj) 0 R"
            + " /MarkInfo << /Marked true >>"
        if icc != nil {
            catalogExtras += " /OutputIntents [ \(outputIntentObj) 0 R ]"
        }
        // `catalogInner` provient d'un décodage Latin-1 ; on ré-encode le
        // catalogue en Latin-1 (et non UTF-8) pour restituer ses octets à
        // l'identique même s'il contient des caractères non-ASCII. Les ajouts
        // ci-dessus sont purement ASCII.
        let catalogBody = "<< \(meta.catalogInner)\(catalogExtras) >>"
        appendObject(meta.catalogObj, catalogBody.data(using: .isoLatin1) ?? Data(catalogBody.utf8))

        // 6. Nouvelle section xref + trailer (/Prev vers l'ancienne)
        let xrefOffset = out.count + 1 // +1 : le \n séparateur ajouté juste avant "xref"
        out.append(Data("\nxref\n".utf8))
        out.append(Data(xrefSection(offsets).utf8))

        var trailer = "trailer\n<< /Size \(newSize) /Root \(meta.catalogObj) 0 R"
        if let infoObj = meta.infoObj { trailer += " /Info \(infoObj) 0 R" }
        trailer += " /Prev \(meta.startxref)"
        trailer += " /ID [ <\(meta.id.0)> <\(meta.id.1)> ]"
        trailer += " >>\nstartxref\n\(xrefOffset)\n%%EOF\n"
        out.append(Data(trailer.utf8))

        return out
    }

    // MARK: - Section xref

    /// Construit une section xref classique avec sous-sections par plages
    /// d'objets contiguës (entrées de 20 octets : `0000000000 00000 n\r\n`).
    private static func xrefSection(_ entries: [(obj: Int, offset: Int)]) -> String {
        let sorted = entries.sorted { $0.obj < $1.obj }
        var result = ""
        var i = 0
        while i < sorted.count {
            var j = i
            while j + 1 < sorted.count && sorted[j + 1].obj == sorted[j].obj + 1 { j += 1 }
            let first = sorted[i].obj
            let count = j - i + 1
            result += "\(first) \(count)\n"
            for k in i...j {
                result += String(format: "%010d 00000 n\r\n", sorted[k].offset)
            }
            i = j + 1
        }
        return result
    }

    // MARK: - Lecture du trailer d'origine

    struct TrailerInfo {
        let startxref: Int
        let size: Int
        let catalogObj: Int
        let infoObj: Int?
        let id: (String, String)
        let catalogInner: String
    }

    private static func parseTrailer(in pdf: Data) -> TrailerInfo? {
        // Mapping 1:1 octet→caractère (Latin-1) pour l'analyse de structure.
        guard let text = String(data: pdf, encoding: .isoLatin1),
              let startxref = lastInt(after: "startxref", in: text),
              let catalogObj = firstInt(matching: #"/Root\s+(\d+)\s+0\s+R"#, in: text),
              let size = firstInt(matching: #"/Size\s+(\d+)"#, in: text),
              let catalogInner = catalogDictInner(objNumber: catalogObj, in: text)
        else { return nil }

        let infoObj = firstInt(matching: #"/Info\s+(\d+)\s+0\s+R"#, in: text)
        let id = firstIDPair(in: text) ?? (synthHexID(), synthHexID())
        return TrailerInfo(
            startxref: startxref,
            size: size,
            catalogObj: catalogObj,
            infoObj: infoObj,
            id: id,
            catalogInner: catalogInner
        )
    }

    /// Contenu interne (entre le premier `<<` et son `>>` apparié) du
    /// dictionnaire catalogue, en gérant l'imbrication.
    private static func catalogDictInner(objNumber: Int, in text: String) -> String? {
        guard let objRange = text.range(of: "\(objNumber) 0 obj"),
              let open = text.range(of: "<<", range: objRange.upperBound..<text.endIndex) else { return nil }
        let chars = Array(text[open.lowerBound...])
        var depth = 0
        var captureStart = 0
        var i = 0
        while i < chars.count - 1 {
            if chars[i] == "<" && chars[i + 1] == "<" {
                depth += 1
                if depth == 1 { captureStart = i + 2 }
                i += 2
            } else if chars[i] == ">" && chars[i + 1] == ">" {
                depth -= 1
                if depth == 0 {
                    return String(chars[captureStart..<i]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                i += 2
            } else {
                i += 1
            }
        }
        return nil
    }

    // MARK: - Parsing helpers

    private static func lastInt(after token: String, in text: String) -> Int? {
        guard let range = text.range(of: token, options: .backwards) else { return nil }
        let tail = text[range.upperBound...]
        let digits = tail.drop { !$0.isNumber }.prefix { $0.isNumber }
        return Int(digits)
    }

    private static func firstInt(matching pattern: String, in text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(match.range(at: 1), in: text) else { return nil }
        return Int(text[r])
    }

    private static func firstIDPair(in text: String) -> (String, String)? {
        let pattern = #"/ID\s*\[\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r0 = Range(match.range(at: 1), in: text),
              let r1 = Range(match.range(at: 2), in: text) else { return nil }
        return (String(text[r0]), String(text[r1]))
    }

    private static func synthHexID() -> String {
        // ID 16 octets dérivé sans aléa (l'aléa n'est pas requis ; on évite une
        // dépendance au RNG). Suffisant pour satisfaire l'exigence /ID de PDF/A.
        "00112233445566778899AABBCCDDEEFF"
    }

    // MARK: - XMP & ICC

    private static func pdfDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMddHHmmss"
        return f.string(from: date)
    }

    private static func srgbICCData() -> Data? {
        guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
              let icc = cs.copyICCData() else { return nil }
        return icc as Data
    }

    private static func xmpPacket(invoiceNumber: String) -> String {
        let title = FacturXXMLBuilder.esc(invoiceNumber)
        return """
        <?xpacket begin="\u{FEFF}" id="W5M0MpCehiHzreSzNTczkc9d"?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
         <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="" xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/">
            <pdfaid:part>3</pdfaid:part>
            <pdfaid:conformance>B</pdfaid:conformance>
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title><rdf:Alt><rdf:li xml:lang="x-default">\(title)</rdf:li></rdf:Alt></dc:title>
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:pdfaExtension="http://www.aiim.org/pdfa/ns/extension/" xmlns:pdfaSchema="http://www.aiim.org/pdfa/ns/schema#" xmlns:pdfaProperty="http://www.aiim.org/pdfa/ns/property#">
            <pdfaExtension:schemas>
              <rdf:Bag>
                <rdf:li rdf:parseType="Resource">
                  <pdfaSchema:schema>Factur-X PDFA Extension Schema</pdfaSchema:schema>
                  <pdfaSchema:namespaceURI>urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#</pdfaSchema:namespaceURI>
                  <pdfaSchema:prefix>fx</pdfaSchema:prefix>
                  <pdfaSchema:property>
                    <rdf:Seq>
                      <rdf:li rdf:parseType="Resource"><pdfaProperty:name>DocumentFileName</pdfaProperty:name><pdfaProperty:valueType>Text</pdfaProperty:valueType><pdfaProperty:category>external</pdfaProperty:category><pdfaProperty:description>Name of the embedded XML invoice file</pdfaProperty:description></rdf:li>
                      <rdf:li rdf:parseType="Resource"><pdfaProperty:name>DocumentType</pdfaProperty:name><pdfaProperty:valueType>Text</pdfaProperty:valueType><pdfaProperty:category>external</pdfaProperty:category><pdfaProperty:description>INVOICE</pdfaProperty:description></rdf:li>
                      <rdf:li rdf:parseType="Resource"><pdfaProperty:name>Version</pdfaProperty:name><pdfaProperty:valueType>Text</pdfaProperty:valueType><pdfaProperty:category>external</pdfaProperty:category><pdfaProperty:description>Version of the Factur-X XML schema</pdfaProperty:description></rdf:li>
                      <rdf:li rdf:parseType="Resource"><pdfaProperty:name>ConformanceLevel</pdfaProperty:name><pdfaProperty:valueType>Text</pdfaProperty:valueType><pdfaProperty:category>external</pdfaProperty:category><pdfaProperty:description>Factur-X conformance level / profile</pdfaProperty:description></rdf:li>
                    </rdf:Seq>
                  </pdfaSchema:property>
                </rdf:li>
              </rdf:Bag>
            </pdfaExtension:schemas>
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:fx="urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#">
            <fx:DocumentType>INVOICE</fx:DocumentType>
            <fx:DocumentFileName>\(attachmentFilename)</fx:DocumentFileName>
            <fx:Version>\(FacturXProfile.version)</fx:Version>
            <fx:ConformanceLevel>\(FacturXProfile.conformanceLevel)</fx:ConformanceLevel>
          </rdf:Description>
         </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="w"?>
        """
    }
}
