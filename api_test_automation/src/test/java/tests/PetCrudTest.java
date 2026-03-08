package tests;

import base.BaseTest;
import io.restassured.response.Response;
import models.Pet;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

public class PetCrudTest extends BaseTest {
    
    private Long createdPetId;

    @Test(priority = 1, description = "Create a new pet successfully")
    public void testCreatePet() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Karabaş")
                .status("available")
                .photoUrls(Arrays.asList("https://example.com/photo1.jpg"))
                .category(Pet.Category.builder()
                        .id(1L)
                        .name("Dogs")
                        .build())
                .tags(Arrays.asList(
                        Pet.Tag.builder().id(1L).name("friendly").build()
                ))
                .build();

        Response response = apiClient.createPet(pet);
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getContentType()).contains("application/json");
        
        Pet createdPet = response.as(Pet.class);
        createdPetId = createdPet.getId();
        
        assertThat(createdPet.getId()).isNotNull();
        assertThat(createdPet.getName()).isEqualTo("Karabaş");
        assertThat(createdPet.getStatus()).isEqualTo("available");
        assertThat(createdPet.getPhotoUrls()).isNotEmpty();
        assertThat(createdPet.getCategory()).isNotNull();
        assertThat(createdPet.getCategory().getName()).isEqualTo("Dogs");
        assertThat(createdPet.getTags()).isNotEmpty();
        System.out.println("✓ Test Passed: Pet created successfully with ID: " + createdPetId);
    }

    @Test(priority = 2, description = "Get pet by ID successfully")
    public void testGetPetById() {
        Pet pet = createTestPet("Boncuk");
        
        Response response = apiClient.getPetById(pet.getId());
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getContentType()).contains("application/json");
        
        Pet retrievedPet = response.as(Pet.class);
        assertThat(retrievedPet.getId()).isNotNull().isEqualTo(pet.getId());
        assertThat(retrievedPet.getName()).isNotNull().isEqualTo("Boncuk");
        assertThat(retrievedPet.getPhotoUrls()).isNotNull();
        System.out.println("✓ Test Passed: Pet retrieved successfully");
    }

    @Test(priority = 3, description = "Update existing pet successfully")
    public void testUpdatePet() {
        Pet pet = createTestPet("Pamuk");
        
        pet.setName("Pamuk Updated");
        pet.setStatus("sold");
        
        Response response = apiClient.updatePet(pet);
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet updatedPet = response.as(Pet.class);
        assertThat(updatedPet.getName()).isEqualTo("Pamuk Updated");
        assertThat(updatedPet.getStatus()).isEqualTo("sold");
        System.out.println("✓ Test Passed: Pet updated successfully");
    }

    @Test(priority = 4, description = "Delete pet successfully")
    public void testDeletePet() {
        Pet pet = createTestPet("Minnoş");
        
        Response deleteResponse = apiClient.deletePet(pet.getId());
        System.out.println("✓ Delete Response Status: " + deleteResponse.getStatusCode());
        assertThat(deleteResponse.getStatusCode()).isEqualTo(200);
        
        Response getResponse = apiClient.getPetById(pet.getId());
        System.out.println("✓ Get After Delete Response Status: " + getResponse.getStatusCode());
        assertThat(getResponse.getStatusCode()).isEqualTo(404);
        System.out.println("✓ Test Passed: Pet deleted successfully");
    }

    @Test(priority = 5, description = "Get pet with invalid ID returns 404")
    public void testGetPetWithInvalidId() {
        Response response = apiClient.getPetById(999999999L);
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(404);
        System.out.println("✓ Test Passed: Invalid ID returned 404 as expected");
    }

    @Test(priority = 6, description = "Find pets by status")
    public void testFindPetsByStatus() {
        createTestPet("Available Pet", "available");
        
        Response response = apiClient.findPetsByStatus("available");
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getContentType()).contains("application/json");
        
        List<Pet> pets = Arrays.asList(response.as(Pet[].class));
        assertThat(pets).isNotEmpty();
        long availablePets = pets.stream().filter(p -> "available".equals(p.getStatus())).count();
        assertThat(availablePets).isGreaterThan(0);
        assertThat(pets).allMatch(p -> p.getId() != null);
        System.out.println("✓ Test Passed: Found " + availablePets + " pets with status 'available' out of " + pets.size() + " total");
    }

    @Test(priority = 7, description = "Create pet with minimal data")
    public void testCreatePetWithMinimalData() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Minimal Pet")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .build();
        
        Response response = apiClient.createPet(pet);
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = response.as(Pet.class);
        createdPetId = createdPet.getId();
        assertThat(createdPet.getName()).isEqualTo("Minimal Pet");
        System.out.println("✓ Test Passed: Pet created with minimal data");
    }

    @Test(priority = 8, description = "Find pets by tags")
    public void testFindPetsByTags() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Tagged Pet")
                .status("available")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .tags(Arrays.asList(
                        Pet.Tag.builder().id(1L).name("cute").build(),
                        Pet.Tag.builder().id(2L).name("playful").build()
                ))
                .build();
        
        apiClient.createPet(pet);
        createdPetId = pet.getId();
        
        Response response = apiClient.findPetsByTags("cute", "playful");
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        List<Pet> pets = Arrays.asList(response.as(Pet[].class));
        assertThat(pets).isNotEmpty();
        System.out.println("✓ Test Passed: Found " + pets.size() + " pets with specified tags");
    }

    @Test(priority = 9, description = "Update pet with form data")
    public void testUpdatePetWithForm() {
        Pet pet = createTestPet("Form Pet");
        
        Response response = apiClient.updatePetWithForm(pet.getId(), "Form Pet Updated", "sold");
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Response getResponse = apiClient.getPetById(pet.getId());
        Pet updatedPet = getResponse.as(Pet.class);
        
        assertThat(updatedPet.getName()).isEqualTo("Form Pet Updated");
        assertThat(updatedPet.getStatus()).isEqualTo("sold");
        System.out.println("✓ Test Passed: Pet updated via form data");
    }

    @Test(priority = 10, description = "Update pet creates new pet if not exists")
    public void testUpdateNonExistentPet() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("New Pet via Update")
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .status("available")
                .build();
        
        Response response = apiClient.updatePet(pet);
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(200);
        
        Pet updatedPet = response.as(Pet.class);
        createdPetId = updatedPet.getId();
        assertThat(updatedPet.getName()).isEqualTo("New Pet via Update");
        System.out.println("✓ Test Passed: Non-existent pet created via update");
    }

    @Test(priority = 11, description = "Delete pet with invalid ID returns 404")
    public void testDeletePetWithInvalidId() {
        Response response = apiClient.deletePet(999999999L);
        
        System.out.println("✓ Response Status: " + response.getStatusCode());
        assertThat(response.getStatusCode()).isEqualTo(404);
        System.out.println("✓ Test Passed: Delete with invalid ID returns 404 as expected");
    }

    @Test(priority = 12, description = "Find pets by multiple statuses")
    public void testFindPetsByMultipleStatuses() {
        createTestPet("Pending Pet", "pending");
        createTestPet("Sold Pet", "sold");
        
        Response pendingResponse = apiClient.findPetsByStatus("pending");
        System.out.println("✓ Pending Response Status: " + pendingResponse.getStatusCode());
        assertThat(pendingResponse.getStatusCode()).isEqualTo(200);
        
        Response soldResponse = apiClient.findPetsByStatus("sold");
        System.out.println("✓ Sold Response Status: " + soldResponse.getStatusCode());
        assertThat(soldResponse.getStatusCode()).isEqualTo(200);
        
        List<Pet> pendingPets = Arrays.asList(pendingResponse.as(Pet[].class));
        List<Pet> soldPets = Arrays.asList(soldResponse.as(Pet[].class));
        
        assertThat(pendingPets).allMatch(p -> "pending".equals(p.getStatus()));
        assertThat(soldPets).allMatch(p -> "sold".equals(p.getStatus()));
        System.out.println("✓ Test Passed: Found " + pendingPets.size() + " pending and " + soldPets.size() + " sold pets");
    }

    @Test(priority = 13, description = "Create pet and verify all fields are persisted")
    public void testCreatePetVerifyAllFields() {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name("Complete Pet")
                .status("available")
                .photoUrls(Arrays.asList("https://example.com/photo1.jpg", "https://example.com/photo2.jpg"))
                .category(Pet.Category.builder()
                        .id(5L)
                        .name("Cats")
                        .build())
                .tags(Arrays.asList(
                        Pet.Tag.builder().id(10L).name("fluffy").build(),
                        Pet.Tag.builder().id(11L).name("cute").build()
                ))
                .build();

        Response createResponse = apiClient.createPet(pet);
        assertThat(createResponse.getStatusCode()).isEqualTo(200);
        
        Pet createdPet = createResponse.as(Pet.class);
        createdPetId = createdPet.getId();

        Response getResponse = apiClient.getPetById(createdPet.getId());
        Pet fetchedPet = getResponse.as(Pet.class);

        assertThat(fetchedPet.getName()).isEqualTo("Complete Pet");
        assertThat(fetchedPet.getStatus()).isEqualTo("available");
        assertThat(fetchedPet.getPhotoUrls()).hasSize(2);
        assertThat(fetchedPet.getCategory()).isNotNull();
        assertThat(fetchedPet.getCategory().getName()).isEqualTo("Cats");
        assertThat(fetchedPet.getTags()).hasSize(2);
        
        System.out.println("✓ Test Passed: All fields persisted correctly");
    }

    @Test(priority = 14, description = "Update pet status transitions")
    public void testPetStatusTransitions() {
        Pet pet = createTestPet("Status Test Pet", "available");

        pet.setStatus("pending");
        Response response1 = apiClient.updatePet(pet);
        assertThat(response1.getStatusCode()).isEqualTo(200);
        assertThat(response1.as(Pet.class).getStatus()).isEqualTo("pending");

        pet.setStatus("sold");
        Response response2 = apiClient.updatePet(pet);
        assertThat(response2.getStatusCode()).isEqualTo(200);
        assertThat(response2.as(Pet.class).getStatus()).isEqualTo("sold");

        System.out.println("✓ Test Passed: Status transitions work correctly");
    }

    @Test(priority = 15, description = "Create multiple pets and verify uniqueness")
    public void testCreateMultiplePetsVerifyUniqueness() {
        Pet pet1 = createTestPet("Pet One", "available");
        Pet pet2 = createTestPet("Pet Two", "available");
        Pet pet3 = createTestPet("Pet Three", "available");

        assertThat(pet1.getId()).isNotEqualTo(pet2.getId());
        assertThat(pet2.getId()).isNotEqualTo(pet3.getId());
        assertThat(pet1.getId()).isNotEqualTo(pet3.getId());

        apiClient.deletePet(pet2.getId());
        apiClient.deletePet(pet3.getId());

        System.out.println("✓ Test Passed: Multiple pets have unique IDs");
    }

    @Test(priority = 16, description = "Update pet and verify old data is replaced")
    public void testUpdatePetReplacesOldData() {
        Pet pet = createTestPet("Original Name", "available");
        Long originalId = pet.getId();

        pet.setName("Updated Name");
        pet.setStatus("sold");
        pet.setCategory(Pet.Category.builder()
                .id(99L)
                .name("Updated Category")
                .build());

        Response updateResponse = apiClient.updatePet(pet);
        assertThat(updateResponse.getStatusCode()).isEqualTo(200);

        Response getResponse = apiClient.getPetById(originalId);
        Pet updatedPet = getResponse.as(Pet.class);

        assertThat(updatedPet.getName()).isEqualTo("Updated Name");
        assertThat(updatedPet.getStatus()).isEqualTo("sold");
        assertThat(updatedPet.getCategory().getName()).isEqualTo("Updated Category");

        System.out.println("✓ Test Passed: Update replaces old data correctly");
    }

    private Pet createTestPet(String name) {
        return createTestPet(name, "available");
    }

    private Pet createTestPet(String name, String status) {
        Pet pet = Pet.builder()
                .id(System.currentTimeMillis())
                .name(name)
                .status(status)
                .photoUrls(Arrays.asList("https://example.com/photo.jpg"))
                .category(Pet.Category.builder()
                        .id(1L)
                        .name("Dogs")
                        .build())
                .build();

        Response response = apiClient.createPet(pet);
        Pet createdPet = response.as(Pet.class);
        createdPetId = createdPet.getId();
        
        return createdPet;
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
