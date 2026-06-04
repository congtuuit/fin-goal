# Rules to keep WorkManager and Room classes for Google Mobile Ads
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_* { *; }
-keep class androidx.room.** { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.sqlite.** { *; }
