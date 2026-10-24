package org.binarybrains.bbhealthapp.auth.register;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.binarybrains.bbhealthapp.auth.AuthController;
import org.binarybrains.bbhealthapp.auth.register.RegisterRequest;
import org.binarybrains.bbhealthapp.config.security.TokenProvider;
import org.binarybrains.bbhealthapp.config.security.UnAuthorizedHandler;
import org.binarybrains.bbhealthapp.users.UserService;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON_VALUE;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.binarybrains.bbhealthapp.config.loaddata.DataGenerator.createRegisterRequestWithRandomPinCode;
import static org.binarybrains.bbhealthapp.testutils.JsonHelper.getAsJsonString;
import static org.binarybrains.bbhealthapp.testutils.TestDataGenerator.createMockUser;

@WebMvcTest(controllers = RegisterController.class)
@ExtendWith(SpringExtension.class)
class RegisterControllerWebMvcTest {

    @Autowired
    private MockMvc mockMvc;


    @MockBean
    UserService userService;

    @MockBean
    TokenProvider tokenProvider;

    @MockBean
    AuthenticationManager authenticationManager;

    @MockBean
    @Qualifier("BinaryBrainsUserDetailsService")
    UserDetailsService BinaryBrainsUserDetailsService;

    @MockBean
    UnAuthorizedHandler unauthorizedHandler;


    @MockBean
    RegisterService registerService;

/*
    @Test
    public void calling_register_user_with_valid_credentials_should_register_user() throws Exception{



      RegisterRequest registerRequest= createRegisterRequestWithRandomPinCode("someuser");

        when(registerService.addUser(registerRequest)).thenReturn(createMockUser(registerRequest));


        mockMvc.perform(post("/auth/register").contentType(APPLICATION_JSON_VALUE)
                .content(getAsJsonString(registerRequest)))
                .andExpect(status().isOk())
                .andDo(print())
                .andExpect(jsonPath("$.userName", equalTo("someuser")));


    } */

}
