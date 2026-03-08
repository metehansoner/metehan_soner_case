package tests;

import base.BaseTest;
import io.restassured.response.Response;
import models.Pet;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

public class PetImageUploadTest extends BaseTest {
    
    private Long testPetId;
    private File tempImageFile;

    @BeforeMethod
    public void setupImageTest() throws IOException {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Image Test Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .status("available")
                .build();

        Response response = apiClient.createPet(pet);
        testPetId = response.as(Pet.class).getId();

        tempImageFile = File.createTempFile("test-image", ".jpg");
        try (FileWriter writer = new FileWriter(tempImageFile)) {
            writer.write("fake image content for testing");
        }
    }

    @Test(priority = 1, description = "Upload image successfully")
    public void testUploadImageSuccess() {
        Response response = apiClient.uploadImage(testPetId, "Test image metadata", tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getContentType()).contains("application/json");
        
        String responseBody = response.getBody().asString();
        assertThat(responseBody).isNotEmpty();
        assertThat(responseBody).contains("code");
        assertThat(responseBody).contains("message");
        
        System.out.println("✓ Test Passed: Image uploaded successfully");
    }

    @Test(priority = 2, description = "Upload image with metadata")
    public void testUploadImageWithMetadata() {
        String metadata = "Pet profile picture - high resolution";
        Response response = apiClient.uploadImage(testPetId, metadata, tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        String responseBody = response.getBody().asString();
        assertThat(responseBody).contains("additionalMetadata");
        
        System.out.println("✓ Test Passed: Image uploaded with metadata");
    }

    @Test(priority = 3, description = "Upload image without metadata")
    public void testUploadImageWithoutMetadata() {
        Response response = apiClient.uploadImage(testPetId, "", tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Image uploaded without metadata");
    }

    @Test(priority = 4, description = "Upload image to non-existent pet - API accepts (no validation)")
    public void testUploadImageToNonExistentPet() {
        Long nonExistentPetId = 999999999L;
        Response response = apiClient.uploadImage(nonExistentPetId, "Test metadata", tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Upload to non-existent pet is accepted (API vulnerability)");
    }

    @Test(priority = 5, description = "Upload without file - API returns 500 server error")
    public void testUploadWithoutFile() {
        Response response = apiClient.uploadImageWithoutFile(testPetId, "Metadata only");

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(500);
        System.out.println("✓ Test Passed: Upload without file causes server error (poor error handling)");
    }

    @Test(priority = 6, description = "Upload image with negative pet ID - API accepts (no validation)")
    public void testUploadImageWithNegativePetId() {
        Response response = apiClient.uploadImage(-1L, "Test metadata", tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Negative pet ID is accepted (API vulnerability)");
    }

    @Test(priority = 7, description = "Upload image with zero pet ID - API accepts (no validation)")
    public void testUploadImageWithZeroPetId() {
        Response response = apiClient.uploadImage(0L, "Test metadata", tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Zero pet ID is accepted (API vulnerability)");
    }

    @Test(priority = 8, description = "Upload image with special characters in metadata")
    public void testUploadImageWithSpecialCharactersMetadata() {
        String specialMetadata = "<script>alert('XSS')</script> & special chars: @#$%";
        Response response = apiClient.uploadImage(testPetId, specialMetadata, tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Special characters in metadata handled");
    }

    @Test(priority = 9, description = "Upload image with very long metadata - API accepts (no validation)")
    public void testUploadImageWithLongMetadata() {
        String longMetadata = "A".repeat(5000);
        Response response = apiClient.uploadImage(testPetId, longMetadata, tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Long metadata is accepted (API vulnerability)");
    }

    @Test(priority = 10, description = "Upload multiple images to same pet")
    public void testUploadMultipleImages() throws IOException {
        Response response1 = apiClient.uploadImage(testPetId, "First image", tempImageFile);
        assertThat(response1.getStatusCode()).isEqualTo(200);

        File secondImage = File.createTempFile("test-image-2", ".jpg");
        try (FileWriter writer = new FileWriter(secondImage)) {
            writer.write("second fake image content");
        }
        
        Response response2 = apiClient.uploadImage(testPetId, "Second image", secondImage);
        assertThat(response2.getStatusCode()).isEqualTo(200);

        secondImage.delete();
        
        System.out.println("✓ Response Status: " + response2.getStatusCode());
        System.out.println("✓ Test Passed: Multiple images uploaded successfully");
    }

    @Test(priority = 11, description = "Upload image with empty string metadata")
    public void testUploadImageWithEmptyMetadata() {
        Response response = apiClient.uploadImage(testPetId, "", tempImageFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Empty metadata is accepted");
    }

    @Test(priority = 12, description = "Upload large file - API accepts (no size validation)")
    public void testUploadLargeFile() throws IOException {
        File largeFile = File.createTempFile("large-image", ".jpg");
        byte[] largeContent = new byte[1024 * 1024]; // 1MB
        Arrays.fill(largeContent, (byte) 'A');
        Files.write(largeFile.toPath(), largeContent);

        Response response = apiClient.uploadImage(testPetId, "Large file test", largeFile);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        largeFile.delete();
        System.out.println("✓ Test Passed: Large file upload is accepted (no size limit)");
    }

    @AfterMethod
    public void cleanup() {
        if (testPetId != null) {
            try {
                apiClient.deletePet(testPetId);
            } catch (Exception e) {
            }
        }
        
        if (tempImageFile != null && tempImageFile.exists()) {
            tempImageFile.delete();
        }
    }
}
