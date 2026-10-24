package org.binarybrains.bbhealthapp.testrequests;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.hamcrest.MatcherAssert;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.binarybrains.bbhealthapp.auth.AuthController;
import org.binarybrains.bbhealthapp.auth.models.LoginRequest;
import org.binarybrains.bbhealthapp.auth.models.LoginResponse;
import org.binarybrains.bbhealthapp.testrequests.models.CreateTestRequest;
import org.binarybrains.bbhealthapp.testrequests.models.RequestStatus;
import org.binarybrains.bbhealthapp.users.UserService;
import org.binarybrains.bbhealthapp.users.models.Gender;

import static org.hamcrest.Matchers.equalTo;
import static org.springframework.http.MediaType.APPLICATION_JSON_VALUE;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.binarybrains.bbhealthapp.testutils.JsonHelper.getAsJsonString;
import static org.binarybrains.bbhealthapp.testutils.TestData.*;
import static org.binarybrains.bbhealthapp.testutils.TestDataGenerator.createLoginRequestWIth;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Slf4j
class TestRequestControllerAcceptanceTest {



    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;



    @Autowired
    private AuthController authController;


    private String getAccessToken()  {

        String username =DEFAULT_USER;
         String password =DEFAULT_PASSWORD;
        LoginRequest loginRequest = createLoginRequestWIth(username, password);

        ResponseEntity<LoginResponse> loginResponse = (ResponseEntity<LoginResponse>) authController.login(loginRequest);
        return loginResponse.getBody().getToken();
    }


    public static HttpEntity createHttpEntityWithToken(Object objectToPost, String token) throws JsonProcessingException {
        final ObjectMapper mapper = new ObjectMapper();
        HttpHeaders headers = getHttpHeaders(token);
        String s = mapper.writeValueAsString(objectToPost);
        return new HttpEntity(s, headers);
    }

    public static HttpHeaders getHttpHeaders(String accessToken) {
        HttpHeaders headers = new HttpHeaders();

        if(null != accessToken && accessToken.trim().length() >0)
            headers.set("Authorization", "Bearer "+accessToken);

        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }



/*
    @Test
    public void calling_register_testrequest_should_create_test_request() throws Exception{


        final String user = "someone";
        CreateTestRequest createTestRequest = createTestRequestWith(user, "143456789");
        final HttpEntity requestEntity = createHttpEntityWithToken(createTestRequest, getAccessToken());

        String url = "http://localhost:" + port + "/api/testrequests";

        final ResponseEntity<TestRequest> entity = restTemplate.postForEntity(url, requestEntity, TestRequest.class);

        TestRequest result = entity.getBody();

     //   log.info(result.toString());
        MatcherAssert.assertThat(result.getStatus(),equalTo(RequestStatus.INITIATED));


    } */

    public CreateTestRequest createTestRequestWith(String user, String phoneNumber) {
        CreateTestRequest createTestRequest = new CreateTestRequest();
        createTestRequest.setAddress("some Addres");
        createTestRequest.setAge(98);
        createTestRequest.setEmail("someone" + phoneNumber + "@somedomain.com");
        createTestRequest.setGender(Gender.MALE);
        createTestRequest.setName(user);
        createTestRequest.setPhoneNumber(phoneNumber);
        createTestRequest.setPinCode(716768);
        return createTestRequest;
    }

}
