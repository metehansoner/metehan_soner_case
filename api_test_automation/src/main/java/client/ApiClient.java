package client;

import config.Config;
import io.restassured.RestAssured;
import io.restassured.filter.log.RequestLoggingFilter;
import io.restassured.filter.log.ResponseLoggingFilter;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import models.Pet;

public class ApiClient {
    
    private RequestSpecification getBaseRequest() {
        return RestAssured.given()
                .baseUri(Config.BASE_URL)
                .contentType(ContentType.JSON)
                .accept(ContentType.JSON)
                .filter(new TestLogger())
                .filter(new RequestLoggingFilter())
                .filter(new ResponseLoggingFilter());
    }

    public Response createPet(Pet pet) {
        return getBaseRequest()
                .body(pet)
                .post(Config.PET_ENDPOINT);
    }

    public Response getPetById(Long petId) {
        return getBaseRequest()
                .pathParam("petId", petId)
                .get(Config.PET_ENDPOINT + "/{petId}");
    }

    public Response updatePet(Pet pet) {
        return getBaseRequest()
                .body(pet)
                .put(Config.PET_ENDPOINT);
    }

    public Response deletePet(Long petId) {
        return getBaseRequest()
                .pathParam("petId", petId)
                .delete(Config.PET_ENDPOINT + "/{petId}");
    }

    public Response findPetsByStatus(String status) {
        return getBaseRequest()
                .queryParam("status", status)
                .get(Config.PET_ENDPOINT + "/findByStatus");
    }

    public Response findPetsByTags(String... tags) {
        return getBaseRequest()
                .queryParam("tags", String.join(",", tags))
                .get(Config.PET_ENDPOINT + "/findByTags");
    }

    public Response updatePetWithForm(Long petId, String name, String status) {
        return getBaseRequest()
                .contentType("application/x-www-form-urlencoded")
                .formParam("name", name)
                .formParam("status", status)
                .post(Config.PET_ENDPOINT + "/" + petId);
    }

    public Response uploadImage(Long petId, String additionalMetadata, java.io.File file) {
        return RestAssured.given()
                .baseUri(Config.BASE_URL)
                .filter(new TestLogger())
                .filter(new RequestLoggingFilter())
                .filter(new ResponseLoggingFilter())
                .contentType("multipart/form-data")
                .multiPart("additionalMetadata", additionalMetadata)
                .multiPart("file", file)
                .post(Config.PET_ENDPOINT + "/" + petId + "/uploadImage");
    }

    public Response uploadImageWithoutFile(Long petId, String additionalMetadata) {
        return RestAssured.given()
                .baseUri(Config.BASE_URL)
                .filter(new TestLogger())
                .filter(new RequestLoggingFilter())
                .filter(new ResponseLoggingFilter())
                .contentType("multipart/form-data")
                .multiPart("additionalMetadata", additionalMetadata)
                .post(Config.PET_ENDPOINT + "/" + petId + "/uploadImage");
    }
}
