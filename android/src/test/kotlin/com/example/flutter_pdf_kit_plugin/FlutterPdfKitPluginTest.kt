package com.example.flutter_pdf_kit_plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class FlutterPdfKitPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = FlutterPdfKitPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun extractHighlightedText_returnsExtractedText() {
        val plugin = FlutterPdfKitPlugin()
        val resourceUrl = this.javaClass.classLoader!!.getResource("sample_highlighted.pdf")
        requireNotNull(resourceUrl) { "Test PDF not found in resources." }
        val pdfPath = resourceUrl.path

        val call = MethodCall("extractHighlightedText", mapOf("filePath" to pdfPath))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(Mockito.contains("Expected highlighted text"))
    }

    @Test
    fun extractHighlightedText_returnsErrorIfFileMissing() {
        val plugin = FlutterPdfKitPlugin()
        val call = MethodCall("extractHighlightedText", mapOf("filePath" to "test.pdf"))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(
            Mockito.eq("PDF_ERROR"),
            Mockito.contains("test.pdf"),
            Mockito.isNull()
        )
    }
}