package tests;

import base.BaseTest;
import config.Config;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import models.Pet;
import org.testng.annotations.Test;

import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

public class PetNegativeTest extends BaseTest {

    @Test(priority = 1, description = "Create pet with invalid JSON returns 400")
    public void testCreatePetWithInvalidJson() {
        Response response = RestAssured.given()
                .baseUri(Config.BASE_URL)
                .contentType("application/json")
                .body("{invalid json}")
                .post(Config.PET_ENDPOINT);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(400);
        assertThat(response.getBody()).isNotNull();
        System.out.println("✓ Test Passed: Invalid JSON returns 400");
    }

    @Test(priority = 2, description = "Get pet with string ID returns 404")
    public void testGetPetWithStringId() {
        Response response = RestAssured.given()
                .baseUri(Config.BASE_URL)
                .get(Config.PET_ENDPOINT + "/invalid-id");

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(404);
        System.out.println("✓ Test Passed: String ID returns 404");
    }

    @Test(priority = 3, description = "Get pet with negative ID should return 404")
    public void testGetPetWithNegativeId() {
        Response response = apiClient.getPetById(-1L);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(404);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().asString()).containsIgnoringCase("not found");
        System.out.println("✓ Test Passed: Negative ID returns 404");
    }

    @Test(priority = 4, description = "Update pet with empty body is accepted")
    public void testUpdatePetWithEmptyBody() {
        Response response = RestAssured.given()
                .baseUri(Config.BASE_URL)
                .contentType("application/json")
                .body("{}")
                .put(Config.PET_ENDPOINT);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        System.out.println("✓ Test Passed: Empty body is accepted (no validation)");
    }

    @Test(priority = 5, description = "Delete pet with zero ID should return 404")
    public void testDeletePetWithZeroId() {
        Response response = apiClient.deletePet(0L);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(404);
        System.out.println("✓ Test Passed: Zero ID returns 404");
    }

    @Test(priority = 6, description = "Find pets with invalid status returns empty array")
    public void testFindPetsWithInvalidStatus() {
        Response response = apiClient.findPetsByStatus("invalid-status");

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getBody().asString()).isEqualTo("[]");
        System.out.println("✓ Test Passed: Invalid status returns empty array");
    }

    @Test(priority = 7, description = "Create pet with extremely long name is accepted")
    public void testCreatePetWithLongName() {
        String longName = "A".repeat(10000);
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name(longName)
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getName()).hasSize(10000);
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Long name accepted by API");
    }

    @Test(priority = 8, description = "Create pet with special characters is accepted")
    public void testCreatePetWithSpecialCharacters() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("<script>alert('XSS')</script>")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getName()).isNotNull();
        assertThat(createdPet.getId()).isNotNull();
        assertThat(response.getBody().asString()).contains("script");
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Special characters accepted (XSS vulnerability)");
    }

    @Test(priority = 9, description = "Update pet without photoUrls is accepted")
    public void testUpdatePetWithoutPhotoUrls() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("No Photo Pet")
                .status("available")
                .build();

        Response response = apiClient.updatePet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getId()).isNotNull();
        apiClient.deletePet(pet.getId());
        
        System.out.println("✓ Test Passed: Missing photoUrls accepted");
    }

    @Test(priority = 10, description = "Get pet with maximum Long value - API behavior is inconsistent")
    public void testGetPetWithMaxLongValue() {
        Response response = apiClient.getPetById(Long.MAX_VALUE);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isIn(200, 404);
        assertThat(response.getBody()).isNotNull();
        System.out.println("✓ Test Passed: Max Long value handled (inconsistent behavior)");
    }

    @Test(priority = 11, description = "Create pet with null name is accepted")
    public void testCreatePetWithNullName() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name(null)
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .status("available")
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getId()).isNotNull();
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Null name accepted");
    }

    @Test(priority = 12, description = "Create pet with empty name is accepted")
    public void testCreatePetWithEmptyName() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .status("available")
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getName()).isEqualTo("");
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Empty name accepted");
    }

    @Test(priority = 13, description = "Create pet with invalid status is accepted")
    public void testCreatePetWithInvalidStatus() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Invalid Status Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .status("invalid_status_value")
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getStatus()).isEqualTo("invalid_status_value");
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Invalid status accepted (no validation)");
    }

    @Test(priority = 14, description = "Create pet with invalid photoUrl is accepted")
    public void testCreatePetWithInvalidPhotoUrl() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Invalid URL Pet")
                .photoUrls(Arrays.asList("not-a-valid-url"))
                .status("available")
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getPhotoUrls()).contains("not-a-valid-url");
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Invalid photo URL accepted (no validation)");
    }

    @Test(priority = 15, description = "Create pet with duplicate ID updates existing pet")
    public void testCreatePetWithDuplicateId() {
        long duplicateId = System.currentTimeMillis();
        
        Pet pet1 = Pet.builder()
                .id(duplicateId)
                .name("First Pet")
                .photoUrls(Arrays.asList("https://example.com/photo1.jpg"))
                .status("available")
                .build();

        Response response1 = apiClient.createPet(pet1);
        assertThat(response1.getStatusCode()).isEqualTo(200);

        Pet pet2 = Pet.builder()
                .id(duplicateId)
                .name("Second Pet")
                .photoUrls(Arrays.asList("https://example.com/photo2.jpg"))
                .status("available")
                .build();

        Response response2 = apiClient.createPet(pet2);

        System.out.println("✓ Response Status: " + response2.getStatusCode());
        assertThat(response2.getStatusCode()).isEqualTo(200);
        
        Pet updatedPet = response2.as(Pet.class);
        assertThat(updatedPet.getId()).isEqualTo(duplicateId);
        assertThat(updatedPet.getName()).isEqualTo("Second Pet");
        
        apiClient.deletePet(duplicateId);
        System.out.println("✓ Test Passed: Duplicate ID updates existing pet");
    }

    @Test(priority = 16, description = "Delete already deleted pet returns 404")
    public void testDeleteAlreadyDeletedPet() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("To Be Deleted")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();

        Response createResponse = apiClient.createPet(pet);
        Pet createdPet = createResponse.as(Pet.class);

        Response deleteResponse1 = apiClient.deletePet(createdPet.getId());
        assertThat(deleteResponse1.getStatusCode()).isEqualTo(200);

        Response deleteResponse2 = apiClient.deletePet(createdPet.getId());

        System.out.println("✓ Response Status: " + deleteResponse2.getStatusCode());
        assertThat(deleteResponse2.getStatusCode()).isEqualTo(404);
        System.out.println("✓ Test Passed: Double delete returns 404");
    }

    @Test(priority = 17, description = "Find pets with empty status returns pets with empty status")
    public void testFindPetsWithEmptyStatus() {
        Response response = apiClient.findPetsByStatus("");

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getBody().asString()).isNotEmpty();
        System.out.println("✓ Test Passed: Empty status parameter returns results");
    }

    @Test(priority = 18, description = "Create pet with negative category ID is accepted")
    public void testCreatePetWithNegativeCategoryId() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Negative Category Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .category(Pet.Category.builder()
                        .id(-999L)
                        .name("Invalid Category")
                        .build())
                .status("available")
                .build();

        Response response = apiClient.createPet(pet);

        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        assertThat(createdPet.getCategory().getId()).isEqualTo(-999L);
        apiClient.deletePet(createdPet.getId());
        
        System.out.println("✓ Test Passed: Negative category ID accepted");
    }

    @Test(priority = 19, description = "Update pet form with null values is accepted")
    public void testUpdatePetFormWithNullValues() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Form Test Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .status("available")
                .build();

        Response createResponse = apiClient.createPet(pet);
        Pet createdPet = createResponse.as(Pet.class);

        Response updateResponse = apiClient.updatePetWithForm(createdPet.getId(), null, null);

        System.out.println("✓ Response Status: " + updateResponse.getStatusCode());
        assertThat(updateResponse.getStatusCode()).isEqualTo(200);
        
        apiClient.deletePet(createdPet.getId());
        System.out.println("✓ Test Passed: Null form values accepted");
    }
}
