package dev.openfga.util;

import java.util.function.Predicate;
import java.util.regex.Pattern;

public class StringUtil {
    private StringUtil() {} // Instantiation prevented for utility class.

    private static final Predicate<String> NULL_OR_WS =
            Pattern.compile("^\\s*$").asMatchPredicate();

    /**
     * Returns true when the String is null, empty or contains only whitespace
     * characters.
     *
     * @param str The String being tested.
     * @return true iff str is null, empty or contains only whitespace.
     */
    public static boolean isNullOrWhitespace(String str) {
        return str == null || NULL_OR_WS.test(str);
    }
}
