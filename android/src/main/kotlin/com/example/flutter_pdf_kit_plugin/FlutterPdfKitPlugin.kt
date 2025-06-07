package com.example.flutter_pdf_kit_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.PDAnnotationTextMarkup
import com.tom_roush.pdfbox.text.PDFTextStripperByArea
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
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
        val highlights = mutableListOf<String>()
        val pdfFile = File(pdfPath)
        val document = PDDocument.load(pdfFile)
        highlights.add("loaded pages: ${document.numberOfPages}")
        for (pageIndex in 0 until document.numberOfPages) {
            val page = document.getPage(pageIndex)
            val annotations = page.annotations
            highlights.add("page $pageIndex has ${annotations.size} annotations")
            for (annotation in annotations) {
                if (annotation is PDAnnotationTextMarkup && annotation.subtype == PDAnnotationTextMarkup.SUB_TYPE_HIGHLIGHT) {
                    highlights.add("Found highlight annotation on page $pageIndex")
                    val quads = annotation.quadPoints
                    if (quads != null) {
                        highlights.add("Quad points: ${quads.joinToString(", ")}")
                        // var i = 0
                        // while (i + 7 < quads.size) {
                        //     val xs = listOf(quads[i], quads[i+2], quads[i+4], quads[i+6])
                        //     val ys = listOf(quads[i+1], quads[i+3], quads[i+5], quads[i+7])

                        //     val left = xs.minOrNull() ?: 0f
                        //     val right = xs.maxOrNull() ?: 0f
                        //     val top = ys.minOrNull() ?: 0f
                        //     val bottom = ys.maxOrNull() ?: 0f

                        //     val rect = android.graphics.RectF(left, top, right, bottom)
                        //     val stripper = PDFTextStripperByArea()
                        //     stripper.addRegion("highlight", rect)
                        //     stripper.extractRegions(page)
                        //     val text = stripper.getTextForRegion("highlight").trim()
                        //     if (text.isNotEmpty()) {
                        //         highlights.add(text)
                        //     }

                        //     i += 8
                        // }
                    }
                }
            }
        }

        document.close()
        return highlights
    }
}