package org.binarybrains.bbhealthapp.testrequests.flow;

import org.springframework.data.jpa.repository.JpaRepository;
import org.binarybrains.bbhealthapp.testrequests.TestRequest;

import java.util.List;
import java.util.Optional;


public interface TestRequestFlowRepository extends JpaRepository<TestRequestFlow,Long> {


	Optional<TestRequestFlow> findById(Long id);



	void deleteById(Long id);




	
	List<TestRequestFlow> findByRequest(TestRequest request);


}
