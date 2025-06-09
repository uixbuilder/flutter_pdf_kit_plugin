package com.example.flutter_pdf_kit_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationTextMarkup
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDColor
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDDeviceRGB
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.text.TextPosition

import java.io.File

import android.graphics.RectF

/** FlutterPdfKitPlugin */
class FlutterPdfKitPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        PDFBoxResourceLoader.init(flutterPluginBinding.applicationContext)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_pdf_kit_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "highlightTextInPdf" -> {
                val pdfPath = call.argument<String>("filePath")
                val textToHighlight = call.argument<String>("textToHighlight")
                if (pdfPath == null || textToHighlight == null) {
                    result.error("INVALID_ARGUMENT", "filePath and text are required", null)
                    return
                }
                try {
                    val success = highlightTextInPdf(pdfPath, textToHighlight)
                    result.success(success)
                } catch (e: Exception) {
                    result.error("PDF_ERROR", e.localizedMessage, null)
                }
            }
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "extractHighlightedText" -> {
                val pdfPath = call.argument<String>("filePath")
                if (pdfPath == null) {
                    result.error("INVALID_ARGUMENT", "filePath is required", null)
                    return
                }
                try {
                    val highlightedText = extractHighlightedText(pdfPath)
                    result.success(highlightedText)
                } catch (e: Exception) {
                    result.error("PDF_ERROR", e.localizedMessage, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * Extracts highlighted text from a PDF file.
     * Returns a list of highlighted strings.
     */

    fun extractHighlightedText(pdfPath: String): List<String> {
        val pdfFile = File(pdfPath)
        val document = PDDocument.load(pdfFile)
        val highlightedTexts = mutableListOf<String>()

        for (pageIndex in 0 until document.numberOfPages) {
            val page = document.getPage(pageIndex)
            val annotations = page.annotations
            val pageHeight = page.mediaBox.height

            // 1. Collect all TextPosition objects from this page
            val textPositions = mutableListOf<TextPosition>()
            val stripper = object : PDFTextStripper() {
                override fun processTextPosition(text: TextPosition) {
                    textPositions.add(text)
                }
            }
            stripper.startPage = pageIndex + 1
            stripper.endPage = pageIndex + 1
            stripper.getText(document)

            // 2. For each highlight annotation, check which TextPositions are inside each quad
            for (annotation in annotations) {
                if (annotation is PDAnnotationTextMarkup && annotation.subtype == PDAnnotationTextMarkup.SUB_TYPE_HIGHLIGHT) {
                    val quads = annotation.quadPoints ?: continue
                    var i = 0
                    while (i + 7 < quads.size) {
                        // Get quad rectangle in PDF coordinates
                        val xs = listOf(quads[i], quads[i+2], quads[i+4], quads[i+6])
                        val ys = listOf(quads[i+1], quads[i+3], quads[i+5], quads[i+7])
                        val left = xs.minOrNull() ?: continue
                        val right = xs.maxOrNull() ?: continue
                        var top = ys.maxOrNull() ?: continue
                        var bottom = ys.minOrNull() ?: continue
                        // Convert PDF coordinates (origin bottom) to Java/Android (origin top)
                        top = pageHeight - top
                        bottom = pageHeight - bottom

                        // In PDFBox, y=0 is bottom; so characterCenterY = tp.y - tp.height / 2f is already Java coordinates
                        val highlightedChars = textPositions.filter { tp ->
                            val centerX = tp.x + tp.width / 2f
                            val centerY = tp.y - tp.height / 2f // May need to verify this if highlight is a bit off
                            centerX in left..right && centerY in top..bottom
                        }
                        val highlightedText = highlightedChars.joinToString(separator = "") { it.unicode }
                            .trim()
                        if (highlightedText.isNotEmpty()) {
                            highlightedTexts.add(highlightedText)
                        }
                        i += 8
                    }
                }
            }
        }
        
        document.close()
        return highlightedTexts
    }

    fun highlightTextInPdf(pdfPath: String, textToHighlight: String): Boolean {
        val file = File(pdfPath)
        val document = PDDocument.load(file)
        var highlightAdded = false
        try {
            // Search each page for the text
            for (pageIndex in 0 until document.numberOfPages) {
                val page = document.getPage(pageIndex)
                val rect = findTextBoundingBox(document, pageIndex, textToHighlight)
                if (rect != null) {
                    // Convert the RectF to PDFBox quadPoints (single rectangle)
                    val pageHeight = page.mediaBox.height
                    val left = rect.left
                    val top = pageHeight - rect.top
                    val right = rect.right
                    val bottom = pageHeight - rect.bottom
                    // PDF coordinates: (0,0) is bottom left
                    val quadPoints = floatArrayOf(
                        left, top,      // top left
                        right, top,     // top right
                        left, bottom,   // bottom left
                        right, bottom   // bottom right
                    )

                    val highlight = PDAnnotationTextMarkup(PDAnnotationTextMarkup.SUB_TYPE_HIGHLIGHT)
                    highlight.quadPoints = quadPoints
                    highlight.rectangle = PDRectangle(left, top, right - left, bottom - top)
                    highlight.color = PDColor(floatArrayOf(1f, 1f, 0f), PDDeviceRGB.INSTANCE) // yellow

                    page.annotations.add(highlight)
                    highlightAdded = true
                    break // only highlight first occurrence
                }
            }
            if (highlightAdded) {
                document.save(file)
            }
        } finally {
            document.close()
        }
        return highlightAdded
    }
    
    /**
     * Finds the bounding box (RectF) of the first occurrence of a given text string on a PDF page.
     *
     * @param page The PDPage to search within.
     * @param searchText The text string to find.
     * @return RectF representing the bounding box of the text if found, otherwise null.
     * @throws IOException If there's an error reading the page content.
     */
    private fun findTextBoundingBox(document: PDDocument, pageIndex: Int, searchText: String): RectF? {
        class MatchPosition(val text: StringBuilder, val boxes: MutableList<TextPosition>)
        val matches = mutableListOf<MatchPosition>()
        var result: RectF? = null

        val stripper = object : PDFTextStripper() {
            override fun processTextPosition(text: TextPosition) {
                // Start new match if necessary
                if (matches.isEmpty() || matches.last().text.length == searchText.length) {
                    matches.add(MatchPosition(StringBuilder(), mutableListOf()))
                }
                // Add current character to all current partial matches
                for (match in matches) {
                    match.text.append(text.unicode)
                    match.boxes.add(text)
                    // If the current sequence is longer than searchText, remove from the start
                    if (match.text.length > searchText.length) {
                        match.text.deleteCharAt(0)
                        match.boxes.removeAt(0)
                    }
                    // If it matches searchText, compute bounding box
                    if (match.text.toString() == searchText && result == null) {
                        val first = match.boxes.first()
                        val last = match.boxes.last()
                        val left = first.x
                        val top = first.y
                        val right = last.x + last.width
                        val bottom = last.y - last.height
                        result = RectF(left, top, right, bottom)
                    }
                }
            }
        }
        stripper.startPage = pageIndex + 1
        stripper.endPage = pageIndex + 1
        stripper.getText(document) // Triggers processing
        return result
    }
}