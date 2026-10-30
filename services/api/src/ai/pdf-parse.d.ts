// Made by Dr Ali
// pdf-parse 1.1.1 ships without types. Import the lib entry so the package
// index does not try to read its debug fixture when module.parent is unset.

declare module 'pdf-parse/lib/pdf-parse.js' {
  interface PdfParseResult {
    text: string;
    numpages: number;
  }

  function pdfParse(
    data: Buffer,
    options?: { max?: number },
  ): Promise<PdfParseResult>;

  export default pdfParse;
}
