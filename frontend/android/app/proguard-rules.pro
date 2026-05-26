# Flutter video_player uses ExoPlayer / Media3 under the hood.
# R8 in release mode strips these classes by default — keep them all.
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep interface com.google.android.exoplayer2.** { *; }

# HLS parsing requires these to stay intact
-keep class androidx.media3.exoplayer.hls.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class androidx.media3.extractor.** { *; }

# OkHttp (used internally for network requests)
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
