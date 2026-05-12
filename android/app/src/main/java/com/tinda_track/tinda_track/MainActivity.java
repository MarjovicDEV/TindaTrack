package com.tinda_track.tinda_track;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.tinda_track.tinda_track/export";

  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler(
            (call, result) -> {
              if (!call.method.equals("savePdfToPublicDocuments")) {
                result.notImplemented();
                return;
              }
              String tmpPath = call.argument("tempPath");
              String displayName = call.argument("displayName");
              String folderName = call.argument("folderName");
              if (tmpPath == null || displayName == null || folderName == null) {
                result.error("BAD_ARGS", "Missing tempPath, displayName, or folderName", null);
                return;
              }
              try {
                String saved =
                    savePdfToPublicDocuments(this, tmpPath, displayName, folderName);
                result.success(saved);
              } catch (Exception e) {
                result.error("SAVE_FAILED", e.getMessage(), null);
              }
            });
  }

  private static String savePdfToPublicDocuments(
      Context context, String tmpPath, String displayName, String folderName)
      throws IOException {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      return savePdfWithMediaStore(context, tmpPath, displayName, folderName);
    }
    return savePdfLegacy(tmpPath, displayName, folderName);
  }

  private static String savePdfLegacy(String tmpPath, String displayName, String folderName)
      throws IOException {
    File base = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS);
    File dir = new File(base, folderName);
    if (!dir.exists() && !dir.mkdirs()) {
      throw new IOException("Could not create " + dir.getAbsolutePath());
    }
    File dest = new File(dir, displayName);
    copyFile(tmpPath, dest.getAbsolutePath());
    return dest.getAbsolutePath();
  }

  private static String savePdfWithMediaStore(
      Context context, String tmpPath, String displayName, String folderName)
      throws IOException {
    String[] relativePaths =
        new String[] {
          Environment.DIRECTORY_DOCUMENTS + "/" + folderName,
          Environment.DIRECTORY_DOWNLOADS + "/" + folderName,
        };
    IOException lastException = null;
    for (String relativePath : relativePaths) {
      try {
        return insertPdfMediaStore(context, tmpPath, displayName, relativePath);
      } catch (IOException e) {
        lastException = e;
      }
    }
    if (lastException != null) {
      throw lastException;
    }
    throw new IOException("Save failed");
  }

  private static String insertPdfMediaStore(
      Context context, String tmpPath, String displayName, String relativePath)
      throws IOException {
    ContentResolver resolver = context.getContentResolver();
    ContentValues values = new ContentValues();
    values.put(MediaStore.MediaColumns.DISPLAY_NAME, displayName);
    values.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
    values.put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath);
    values.put(MediaStore.MediaColumns.IS_PENDING, 1);

    Uri collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
    Uri itemUri = resolver.insert(collection, values);
    if (itemUri == null) {
      throw new IOException("Could not create file under " + relativePath);
    }
    try {
      try (OutputStream out = resolver.openOutputStream(itemUri)) {
        if (out == null) {
          throw new IOException("openOutputStream failed");
        }
        try (FileInputStream in = new FileInputStream(tmpPath)) {
          byte[] buf = new byte[8192];
          int n;
          while ((n = in.read(buf)) != -1) {
            out.write(buf, 0, n);
          }
        }
      }
      values.clear();
      values.put(MediaStore.MediaColumns.IS_PENDING, 0);
      resolver.update(itemUri, values, null, null);
      return relativePath + "/" + displayName;
    } catch (IOException e) {
      resolver.delete(itemUri, null, null);
      throw e;
    }
  }

  private static void copyFile(String fromPath, String toPath) throws IOException {
    try (FileInputStream in = new FileInputStream(fromPath);
        FileOutputStream out = new FileOutputStream(toPath)) {
      byte[] buf = new byte[8192];
      int n;
      while ((n = in.read(buf)) != -1) {
        out.write(buf, 0, n);
      }
    }
  }
}
