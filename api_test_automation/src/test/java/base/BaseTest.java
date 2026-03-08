package base;

import client.ApiClient;
import client.TestLogger;
import io.restassured.RestAssured;
import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.BeforeMethod;

import java.lang.reflect.Method;

public class BaseTest {
    protected ApiClient apiClient;

    @BeforeClass
    public void setup() {
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
        apiClient = new ApiClient();
    }

    @BeforeMethod
    public void beforeMethod(Method method) {
        System.out.println("\n" + "=".repeat(80));
        System.out.println("TEST: " + method.getName());
        System.out.println("DESCRIPTION: " + (method.getAnnotation(org.testng.annotations.Test.class).description()));
        System.out.println("=".repeat(80));
    }

    @AfterSuite
    public void tearDown() {
        TestLogger.close();
        System.out.println("\n✓ Test execution log saved to: test-execution.log");
    }
}
