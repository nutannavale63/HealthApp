package org.binarybrains.bbhealthapp.testrequests;

import lombok.Data;
import org.binarybrains.bbhealthapp.testrequests.consultation.Consultation;
import org.binarybrains.bbhealthapp.testrequests.lab.LabResult;
import org.binarybrains.bbhealthapp.testrequests.models.RequestStatus;
import org.binarybrains.bbhealthapp.users.User;
import org.binarybrains.bbhealthapp.users.models.Gender;

import javax.persistence.*;
import java.time.LocalDate;

@Data
@Entity
public class TestRequest {


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long requestId;

    @ManyToOne
    private User createdBy;

    private LocalDate created=LocalDate.now();

    private RequestStatus status = RequestStatus.INITIATED;


    private String name;
    private Gender gender;
    private String address;
    private Integer age;
    private String email;
    private String phoneNumber;
    private Integer pinCode;


    @OneToOne(mappedBy="request")
    Consultation consultation;

    @OneToOne(mappedBy="request")
    LabResult labResult;

}
