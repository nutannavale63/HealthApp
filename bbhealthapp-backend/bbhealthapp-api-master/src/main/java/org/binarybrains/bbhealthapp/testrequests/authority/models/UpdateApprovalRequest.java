package org.binarybrains.bbhealthapp.testrequests.authority.models;

import lombok.Data;
import org.binarybrains.bbhealthapp.users.models.AccountStatus;

import javax.validation.constraints.NotNull;

@Data
public class UpdateApprovalRequest {

    @NotNull
    Long userId;

    public Long getUserId() {
		return userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	@NotNull
    AccountStatus status;

	public AccountStatus getStatus() {
		return status;
	}

	public void setStatus(AccountStatus status) {
		this.status = status;
	}


}
