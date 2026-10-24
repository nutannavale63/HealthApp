package org.binarybrains.bbhealthapp.testrequests.authority.models;

import lombok.Data;
import org.binarybrains.bbhealthapp.users.models.AccountStatus;

import javax.validation.constraints.NotNull;

@Data
public class UpdateApprovalRequest {

    @NotNull
    Long userId;

    @NotNull
    AccountStatus status;


}
