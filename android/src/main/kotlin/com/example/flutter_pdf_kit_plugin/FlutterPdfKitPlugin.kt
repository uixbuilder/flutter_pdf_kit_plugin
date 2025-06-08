package com.example.flutter_pdf_kit_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationTextMarkup
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.text.TextPosition
import java.io.File


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
}