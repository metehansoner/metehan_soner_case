package client;

import io.restassured.filter.Filter;
import io.restassured.filter.FilterContext;
import io.restassured.response.Response;
import io.restassured.specification.FilterableRequestSpecification;
import io.restassured.specification.FilterableResponseSpecification;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class TestLogger implements Filter {
    
    private static final String LOG_FILE = "test-execution.log";
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static PrintWriter writer;
    
    static {
        try {
            writer = new PrintWriter(new FileWriter(LOG_FILE, false));
            writer.println("================================================================================");
            writer.println("API TEST EXECUTION LOG");
            writer.println("Started at: " + LocalDateTime.now().format(DATE_FORMATTER));
            writer.println("================================================================================");
            writer.println();
            writer.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public Response filter(FilterableRequestSpecification requestSpec, 
                          FilterableResponseSpecification responseSpec, 
                          FilterContext ctx) {
        
        logRequest(requestSpec);
        
        Response response = ctx.next(requestSpec, responseSpec);
        
        logResponse(response);
        
        return response;
    }

    private void logRequest(FilterableRequestSpecification requestSpec) {
        try {
            writer.println("================================================================================");
            writer.println("REQUEST");
            writer.println("================================================================================");
            writer.println("Timestamp: " + LocalDateTime.now().format(DATE_FORMATTER));
            writer.println("Method: " + requestSpec.getMethod());
            writer.println("URL: " + requestSpec.getURI());
            
            if (requestSpec.getQueryParams() != null && !requestSpec.getQueryParams().isEmpty()) {
                writer.println("Query Params: " + requestSpec.getQueryParams());
            }
            
            if (requestSpec.getFormParams() != null && !requestSpec.getFormParams().isEmpty()) {
                writer.println("Form Params: " + requestSpec.getFormParams());
            }
            
            if (requestSpec.getHeaders() != null) {
                writer.println("Headers:");
                requestSpec.getHeaders().forEach(header -> 
                    writer.println("  " + header.getName() + ": " + header.getValue())
                );
            }
            
            if (requestSpec.getBody() != null && !requestSpec.getContentType().contains("multipart")) {
                writer.println("Request Body:");
                writer.println(requestSpec.getBody().toString());
            } else if (requestSpec.getContentType().contains("multipart")) {
                writer.println("Request Body: [Multipart Form Data]");
            }
            
            writer.println();
            writer.flush();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void logResponse(Response response) {
        try {
            writer.println("--------------------------------------------------------------------------------");
            writer.println("RESPONSE");
            writer.println("--------------------------------------------------------------------------------");
            writer.println("Status Code: " + response.getStatusCode());
            writer.println("Status Line: " + response.getStatusLine());
            writer.println("Response Time: " + response.getTime() + "ms");
            
            if (response.getHeaders() != null) {
                writer.println("Headers:");
                response.getHeaders().forEach(header -> 
                    writer.println("  " + header.getName() + ": " + header.getValue())
                );
            }
            
            String contentType = response.getContentType();
            if (contentType != null && contentType.contains("json")) {
                writer.println("Response Body:");
                try {
                    String body = response.getBody().asString();
                    if (body != null && !body.isEmpty()) {
                        writer.println(body);
                    } else {
                        writer.println("[Empty Response]");
                    }
                } catch (Exception e) {
                    writer.println("[Unable to parse response body]");
                }
            } else if (contentType != null && contentType.contains("html")) {
                writer.println("Response Body: [HTML Content - " + response.getBody().asString().length() + " bytes]");
            } else {
                writer.println("Response Body: [" + (contentType != null ? contentType : "Unknown Content Type") + "]");
            }
            
            writer.println();
            writer.println();
            writer.flush();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void close() {
        if (writer != null) {
            writer.println("================================================================================");
            writer.println("TEST EXECUTION COMPLETED");
            writer.println("Ended at: " + LocalDateTime.now().format(DATE_FORMATTER));
            writer.println("================================================================================");
            writer.close();
        }
    }
}
