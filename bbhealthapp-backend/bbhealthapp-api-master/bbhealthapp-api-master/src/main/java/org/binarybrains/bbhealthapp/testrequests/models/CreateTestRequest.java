package org.binarybrains.bbhealthapp.testrequests.models;

import lombok.Data;
import org.binarybrains.bbhealthapp.users.models.Gender;

import javax.validation.constraints.NotNull;

@Data

public class CreateTestRequest {



    private String name;
    private Gender gender;
    private String address;
    private Integer age;

    @NotNull
    private String email;

    @NotNull
    private String phoneNumber;

    @NotNull
    private Integer pinCode;




}
