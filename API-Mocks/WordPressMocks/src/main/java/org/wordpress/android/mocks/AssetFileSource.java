package org.wordpress.android.mocks;

import android.content.res.AssetManager;

import com.github.tomakehurst.wiremock.common.BinaryFile;
import com.github.tomakehurst.wiremock.common.FileSource;
import com.github.tomakehurst.wiremock.common.TextFile;
import com.google.common.base.Function;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.Arrays;
import java.util.List;

import static com.google.common.collect.Iterables.transform;
import static com.google.common.collect.Lists.newArrayList;

/**
 * AssetFileSource provides a the necessary logic for WireMock to load its JSON mappings from Android assets.
 * WireMock has no Android specific behaviour so we must implement asset loading here.
 */
public class AssetFileSource implements FileSource {
    private static final String MOCKS_PATH = "mocks";

    private final AssetManager mAssetManager;
    private final String mPath;

    public AssetFileSource(AssetManager assetManager) {
        this(assetManager, MOCKS_PATH);
    }

    public AssetFileSource(AssetManager assetManager, String path) {
        mAssetManager = assetManager;
        mPath = path;
    }

    @Override public BinaryFile getBinaryFileNamed(String name) {
        return getBinaryFile(mPath + "/" + name);
    }

    @Override public TextFile getTextFileNamed(final String name) {
        return getTextFile(mPath + "/" + name);
    }

    @Override public void createIfNecessary() {
    }

    @Override public FileSource child(String subDirectoryName) {
        return new AssetFileSource(mAssetManager, mPath + "/" + subDirectoryName);
    }

    @Override public String getPath() {
        return mPath;
    }

    @Override public URI getUri() {
        return URI.create(mPath);
    }

    @Override public List<TextFile> listFilesRecursively() {
        List<String> fileList = newArrayList();
        recursivelyAddFilePathsToList(mPath, fileList);
        return toTextFileList(fileList);
    }

    @Override public void writeTextFile(String name, String contents) {
    }

    @Override public void writeBinaryFile(String name, byte[] contents) {
    }

    @Override public boolean exists() {
        return isDirectory(mPath);
    }

    @Override public void deleteFile(String name) {
    }

    private boolean isDirectory(String path) {
        try {
            // Empty directories are not loaded from assets, so this works for an existence check
            // list() seems to be relatively expensive so we may wish to change this
            return mAssetManager.list(path).length > 0;
        } catch (IOException e) {
            return false;
        }
    }

    private void recursivelyAddFilePathsToList(String root, List<String> filePaths) {
        try {
            List<String> fileNames = Arrays.asList(mAssetManager.list(root));
            for (String name : fileNames) {
                String path = root + "/" + name;
                if (isDirectory(path)) {
                    recursivelyAddFilePathsToList(path, filePaths);
                } else {
                    filePaths.add(path);
                }
            }
        } catch (IOException e) {
            // Ignore this
        }
    }

    private List<TextFile> toTextFileList(List<String> filePaths) {
        return newArrayList(transform(filePaths, new Function<String, TextFile>() {
            public TextFile apply(String input) {
                return getTextFile(input);
            }
        }));
    }

    private BinaryFile getBinaryFile(String path) {
        try {
            final InputStream inputStream = mAssetManager.open(path);

            return new BinaryFile(URI.create(path)) {
                @Override public InputStream getStream() {
                    return inputStream;
                }
            };
        } catch (IOException e) {
            return null;
        }
    }

    private TextFile getTextFile(final String path) {
        try {
            final InputStream inputStream = mAssetManager.open(path);

            return new TextFile(URI.create(path)) {
                @Override public InputStream getStream() {
                    return inputStream;
                }

                @Override public String getPath() {
                    return path;
                }
            };
        } catch (IOException e) {
            return null;
        }
    }
}
