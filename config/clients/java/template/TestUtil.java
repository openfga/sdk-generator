package dev.openfga.testutil;

public class TestUtil {

    private TestUtil() {} // Prevent instantiation of this utility class.

    /** Get the name of the test that invokes this function. Returned in the form: "$class.$fn" */
    public static String thisTestName() {
        // Tracing the stack gives an array of:
        // 0: getStackTrace(), 1: getThisFunctionName(), 2: <The calling function>, 3: ...
        StackTraceElement callingFn = Thread.currentThread().getStackTrace()[2];

        return String.format("%s.%s", callingFn.getClassName(), callingFn.getMethodName());
    }
}