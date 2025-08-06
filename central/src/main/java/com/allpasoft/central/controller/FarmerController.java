package com.allpasoft.central.controller;

import com.allpasoft.central.Dto.FarmerDto;
import com.allpasoft.central.entity.Farmer;
import com.allpasoft.central.service.FarmerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/farmers")
public class FarmerController {

    @Autowired
    private FarmerService farmerService;

    @PostMapping
    public Farmer createFarmer(@RequestBody FarmerDto dto) {
        return farmerService.createFarmer(dto);
    }

    @GetMapping
    public List<Farmer> getAllFarmers() {
        return farmerService.getAllFarmers();
    }
}
