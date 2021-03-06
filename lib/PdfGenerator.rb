require 'rubygems'
require 'rjb'
require 'radius'

class PdfGenerator
  # import classes
  Rjb::load(File.join(File.dirname(__FILE__), 'iText.jar'), ['-Djava.awt.headless=true'])
  FileOutputStream = Rjb::import('java.io.FileOutputStream')
  BaseColor = Rjb::import('com.itextpdf.text.BaseColor')
  CMYKColor = Rjb::import('com.itextpdf.text.pdf.CMYKColor')
  Rectangle = Rjb::import('com.itextpdf.text.Rectangle')
  Element = Rjb::import('com.itextpdf.text.Element')
  Document = Rjb::import('com.itextpdf.text.Document')
  Font = Rjb::import('com.itextpdf.text.Font')
  FontFactory = Rjb::import('com.itextpdf.text.FontFactory')
  PageSize = Rjb::import('com.itextpdf.text.PageSize')
  Paragraph = Rjb::import('com.itextpdf.text.Paragraph')
  Phrase = Rjb::import('com.itextpdf.text.Phrase')
  BaseFont = Rjb::import('com.itextpdf.text.pdf.BaseFont')
  ColumnText = Rjb::import('com.itextpdf.text.pdf.ColumnText')
  PdfPageEvent = Rjb::import('com.itextpdf.text.pdf.PdfPageEvent')
  PdfPCell = Rjb::import('com.itextpdf.text.pdf.PdfPCell')
  PdfContentByte = Rjb::import('com.itextpdf.text.pdf.PdfContentByte')
  PdfPTable = Rjb::import('com.itextpdf.text.pdf.PdfPTable')
  PdfWriter = Rjb::import('com.itextpdf.text.pdf.PdfWriter')
  PdfReader = Rjb::import('com.itextpdf.text.pdf.PdfReader')
  
  public
  
  def render_pdf_proof(template, fields, output_path)
    #FontFactory.registerDirectory('/Library/Fonts/')
    #FontFactory.registerDirectory('/System/Library/Fonts/')
    FontFactory.registerDirectory(File.join(RAILS_ROOT, 'lib/fonts')) #fonts should be located here
    
    
    context = get_context(output_path, fields)

    # Setup the parser
    parser = Radius::Parser.new(context, :tag_prefix => 'i')
    parser.parse(template)
  end
  
  
  private
  
  def get_context(output_path, fields)
  
    context = Radius::Context.new do |c|
      # This is the tag for field replacement
      c.define_tag "var" do |tag|
        content = fields[tag.attr['name']]
        if(content.nil? || content.empty?)
          ""
        else
          content
        end
      end
      
      # creates conditions
      c.define_tag "if" do |tag|
        field = tag.attr['name']
        
        # Check if the field is empty
        unless(fields[field].nil? || fields[field].empty?)
          tag.expand
        end
      end
      
      # basic template setup
      c.define_tag "template" do |tag|
        # initialize anything needed for the template
        tag.locals.doc = Document.new()
        tag.locals.writer = PdfWriter.getInstance(tag.locals.doc, FileOutputStream.new(output_path))
        tag.locals.styles = {}

        tag.expand
      end

      c.define_tag "template:styles" do |tag|
        tag.expand
      end

      c.define_tag "template:styles:style" do |tag|
        tag.locals.styles[tag.attr['name']]  = {
          :c => Float(tag.attr['c']),
          :m => Float(tag.attr['m']),
          :y => Float(tag.attr['y']),
          :k => Float(tag.attr['k']),
          :spot => tag.attr['spot'],
          :fontname => tag.attr['fontname'],
          :fontsize => Float(tag.attr['fontsize']),
          :fontleading => Float(tag.attr['fontleading'])
        }

        tag.expand
      end

      c.define_tag "template:page" do |tag|
        # get width and height
        width = Float(tag.attr['width']) * 72
        height = Float(tag.attr['height']) * 72
        pdftemplate = tag.attr['pdf']

        unless(width.nil? || height.nil?)
          tag.locals.doc.setPageSize(Rectangle.new(width, height))
        else
          tag.locals.doc.setPageSize(PageSize.LETTER)
        end

        tag.locals.doc.open()

        unless(pdftemplate.nil?)
          reader = PdfReader.new(File.join(RAILS_ROOT, 'lib', pdftemplate))
          cb = tag.locals.writer.getDirectContent()
          template = tag.locals.writer.getImportedPage(reader, 1)
          cb.addTemplate(template, 0, 0)
        end

        tag.expand

        tag.locals.doc.close()
      end

      c.define_tag "template:page:textblock" do |tag|
        # setup attributes
        x = Float(tag.attr['x']) * 72
        y = Float(tag.attr['y']) * 72
        tag.locals.style = tag.locals.styles[tag.attr['style']] # TODO: Add default style for a backup

        tag.locals.font = FontFactory.getFont(tag.locals.style[:fontname], FontFactory.defaultEncoding, true).getBaseFont()

        if tag.locals.font.nil?
          tag.locals.font = BaseFont.createFont()
        end

        tag.locals.canvas = tag.locals.writer.getDirectContent();
        tag.locals.canvas.beginText()
        tag.locals.canvas.setFontAndSize(tag.locals.font, tag.locals.style[:fontsize])
        tag.locals.canvas.setColorFill(CMYKColor.new(tag.locals.style[:c], tag.locals.style[:m], tag.locals.style[:y], tag.locals.style[:k]))
        tag.locals.canvas.moveText(x, y)
        tag.expand
        tag.locals.canvas.endText()
      end

      c.define_tag "template:page:textblock:textline" do |tag|
        tag.locals.canvas.moveTextWithLeading(0, (0-tag.locals.style[:fontleading]))
        tag.locals.canvas.showText(tag.expand)
      end

      c.define_tag "template:page:textblock:blankline" do |tag|
        tag.locals.canvas.moveTextWithLeading(0, (0-tag.locals.style[:fontleading]))
        tag.locals.canvas.showText("")
      end

      c.define_tag "template:page:textblock:styleline" do |tag|
        tag.locals.canvas.moveTextWithLeading(0, (0-tag.locals.style[:fontleading]))

        tag.expand
      end

      #c.define_tag "template:page:textblock:styleline:span" do |tag|
      c.define_tag "span" do |tag|
        style = tag.locals.styles[tag.attr['style']]
        font = FontFactory.getFont(style[:fontname], FontFactory.defaultEncoding, true).getBaseFont()

        if font.nil?
          font = tag.locals.font
        end

        tag.locals.canvas.setFontAndSize(font, style[:fontsize])
        tag.locals.canvas.showText(tag.expand)
        tag.locals.canvas.setFontAndSize(tag.locals.font, tag.locals.style[:fontsize])
      end
    end
    
    context
  
  end
end