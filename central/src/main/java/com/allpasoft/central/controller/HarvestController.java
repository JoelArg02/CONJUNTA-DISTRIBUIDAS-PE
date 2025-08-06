package com.allpasoft.central.controller;

import com.allpasoft.central.Dto.HarvestDto;
import com.allpasoft.central.Dto.HarvestStatusDto;
import com.allpasoft.central.entity.Harvest;
import com.allpasoft.central.repository.HarvestRepository;
import com.allpasoft.central.service.HarvestService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/cosechas")
public class HarvestController {

    @Autowired
    private HarvestService harvestService;

    @Autowired
    private HarvestRepository harvestRepository;

    // POST /cosechas
    @PostMapping
    public String createHarvest(@RequestBody HarvestDto dto) {
        harvestService.saveHarvest(dto);
        return "Cosecha registrada y evento publicado";
    }

    // PUT /cosechas/{id}/estado
    @PutMapping("/{id}/estado")
    public String updateHarvestStatus(@PathVariable Long id, @RequestBody HarvestStatusDto dto) {
        Optional<Harvest> optionalHarvest = harvestRepository.findById(id);
        if (optionalHarvest.isEmpty()) {
            return "Cosecha no encontrada";
        }
        Harvest harvest = optionalHarvest.get();
        harvest.setEstado(dto.getEstado());
        harvestRepository.save(harvest);
        return "Estado de cosecha actualizado a: " + dto.getEstado();
    }

    @GetMapping
    public List<Harvest> getAllHarvests() {
        return harvestService.getAllHarvests();
    }
}