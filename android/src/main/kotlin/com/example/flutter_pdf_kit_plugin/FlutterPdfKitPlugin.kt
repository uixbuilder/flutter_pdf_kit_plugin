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
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "extractHighlightedText" -> {
                // TODO: allowAddingHighlights is not supported by Android yet.
                // Returns: List<Map<String, Any>>
                // Each item is a map with keys:
                //  - "text": the highlighted string
                //  - "color": highlight color as hex string (or null)
                //  - "rect": a map { "left", "top", "right", "bottom" } in PDF coordinates
                //  - "pageIndex": the page number (0-based)
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
     * Returns a list of maps with keys "text", "color", and "rect".
     */
    fun extractHighlightedText(pdfPath: String): List<Map<String, Any>> {
        val pdfFile = File(pdfPath)
        val document = PDDocument.load(pdfFile)
        val highlightedTexts = mutableListOf<Map<String, Any>>()

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

                    // Get annotation color as hex string if available
                    val colorHex: String = annotation.color?.let { pdColor ->
                        val rgb: FloatArray? = pdColor.components
                        if (rgb != null && rgb.size >= 3) {
                            val r = (rgb[0] * 255).toInt().coerceIn(0, 255)
                            val g = (rgb[1] * 255).toInt().coerceIn(0, 255)
                            val b = (rgb[2] * 255).toInt().coerceIn(0, 255)
                            String.format("#%02X%02X%02X", r, g, b)
                        } else {
                            null
                        }
                    } ?: "#000000"

                    var i = 0
                    while (i + 7 < quads.size) {
                        // Get quad rectangle in PDF coordinates (origin bottom-left)
                        val xs = listOf(quads[i], quads[i+2], quads[i+4], quads[i+6])
                        val ys = listOf(quads[i+1], quads[i+3], quads[i+5], quads[i+7])
                        val left = xs.minOrNull() ?: continue
                        val right = xs.maxOrNull() ?: continue
                        val top = ys.maxOrNull() ?: continue
                        val bottom = ys.minOrNull() ?: continue

                        // In PDFBox, y=0 is bottom; so characterCenterY = tp.y - tp.height / 2f is already Java coordinates
                        val highlightedChars = textPositions.filter { tp ->
                            val centerX = tp.x + tp.width / 2f
                            val centerY = tp.y - tp.height / 2f // May need to verify this if highlight is a bit off
                            centerX in left..right && centerY in (pageHeight - top)..(pageHeight - bottom)
                        }
                        val highlightedText = highlightedChars.joinToString(separator = "") { it.unicode }
                            .trim()
                        if (highlightedText.isNotEmpty()) {
                            val rectMap = mapOf(
                                "left" to left,
                                "top" to bottom,
                                "right" to right,
                                "bottom" to top
                            )
                            val item = mutableMapOf<String, Any>(
                                "text" to highlightedText,
                                "rect" to rectMap,
                                "pageIndex" to pageIndex
                            )
                            item["color"] = colorHex
                            highlightedTexts.add(item)
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