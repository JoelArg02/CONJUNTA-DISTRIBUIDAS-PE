package com.allpasoft.central.service;


import com.allpasoft.central.Dto.FarmerDto;
import com.allpasoft.central.entity.Farmer;
import com.allpasoft.central.repository.FarmerRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class FarmerService {

    @Autowired
    private FarmerRepository farmerRepository;

    public Farmer createFarmer(FarmerDto dto) {
        Farmer farmer = new Farmer();
        farmer.setNombres(dto.getNombres());
        farmer.setApellidos(dto.getApellidos());
        farmer.setEmail(dto.getEmail());
        farmer.setTelefono(dto.getTelefono());
        farmer.setCreadoEn(LocalDateTime.now());

        return farmerRepository.save(farmer);
    }

    public List<Farmer> getAllFarmers() {
        return farmerRepository.findAll();
    }
}
