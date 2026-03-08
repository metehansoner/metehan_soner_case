package tests;

import base.BaseTest;
import io.restassured.response.Response;
import models.Pet;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.Arrays;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.lessThan;

public class PetPerformanceTest extends BaseTest {
    
    private Long createdPetId;

    @Test(priority = 1, description = "Create pet response time should be less than 3 seconds")
    public void testCreatePetPerformance() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Performance Test Pet")
                .status("available")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        long startTime = System.currentTimeMillis();
        Response response = apiClient.createPet(pet);
        long endTime = System.currentTimeMillis();
        long responseTime = endTime - startTime;

        System.out.println("✓ Response Status: " + response.getStatusCode());
        System.out.println("✓ Response Time: " + responseTime + "ms");
        
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(responseTime).isLessThan(3000L);
        
        response.then().time(lessThan(3000L), TimeUnit.MILLISECONDS);
        
        Pet createdPet = response.as(Pet.class);
        createdPetId = createdPet.getId();
        System.out.println("✓ Test Passed: Response time is acceptable");
    }

    @Test(priority = 2, description = "Get pet response time should be less than 2 seconds")
    public void testGetPetPerformance() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Get Performance Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        apiClient.createPet(pet);
        createdPetId = pet.getId();

        long startTime = System.currentTimeMillis();
        Response response = apiClient.getPetById(pet.getId());
        long endTime = System.currentTimeMillis();
        long responseTime = endTime - startTime;

        System.out.println("✓ Response Status: " + response.getStatusCode());
        System.out.println("✓ Response Time: " + responseTime + "ms");
        
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(responseTime).isLessThan(2000L);
        
        response.then().time(lessThan(2000L), TimeUnit.MILLISECONDS);
        System.out.println("✓ Test Passed: Get operation is fast");
    }

    @Test(priority = 3, description = "Update pet response time should be less than 3 seconds")
    public void testUpdatePetPerformance() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Update Performance Pet")
                .status("available")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        apiClient.createPet(pet);
        createdPetId = pet.getId();

        pet.setStatus("sold");

        long startTime = System.currentTimeMillis();
        Response response = apiClient.updatePet(pet);
        long endTime = System.currentTimeMillis();
        long responseTime = endTime - startTime;

        System.out.println("✓ Response Status: " + response.getStatusCode());
        System.out.println("✓ Response Time: " + responseTime + "ms");
        
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(responseTime).isLessThan(3000L);
        
        response.then().time(lessThan(3000L), TimeUnit.MILLISECONDS);
        System.out.println("✓ Test Passed: Update operation is fast");
    }

    @Test(priority = 4, description = "Delete pet response time should be less than 2 seconds")
    public void testDeletePetPerformance() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Delete Performance Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        apiClient.createPet(pet);
        createdPetId = pet.getId();

        long startTime = System.currentTimeMillis();
        Response response = apiClient.deletePet(pet.getId());
        long endTime = System.currentTimeMillis();
        long responseTime = endTime - startTime;

        System.out.println("✓ Response Status: " + response.getStatusCode());
        System.out.println("✓ Response Time: " + responseTime + "ms");
        
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(responseTime).isLessThan(2000L);
        
        response.then().time(lessThan(2000L), TimeUnit.MILLISECONDS);
        
        createdPetId = null; // Already deleted
        System.out.println("✓ Test Passed: Delete operation is fast");
    }

    @Test(priority = 5, description = "Find by status response time should be less than 3 seconds")
    public void testFindByStatusPerformance() {
        long startTime = System.currentTimeMillis();
        Response response = apiClient.findPetsByStatus("available");
        long endTime = System.currentTimeMillis();
        long responseTime = endTime - startTime;

        System.out.println("✓ Response Status: " + response.getStatusCode());
        System.out.println("✓ Response Time: " + responseTime + "ms");
        
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(responseTime).isLessThan(3000L);
        
        response.then().time(lessThan(3000L), TimeUnit.MILLISECONDS);
        System.out.println("✓ Test Passed: Search operation is fast");
    }

    @AfterMethod
    public void cleanup() {
        if (createdPetId != null) {
            try {
                apiClient.deletePet(createdPetId);
            } catch (Exception e) {
            }
            createdPetId = null;
        }
    }
}
