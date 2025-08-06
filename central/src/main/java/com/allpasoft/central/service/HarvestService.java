    package com.allpasoft.central.service;

    import com.allpasoft.central.Dto.HarvestDto;
    import com.allpasoft.central.entity.Farmer;
    import com.allpasoft.central.entity.Harvest;
    import com.allpasoft.central.publisher.HarvestProducer;
    import com.allpasoft.central.repository.FarmerRepository;
    import com.allpasoft.central.repository.HarvestRepository;
    import org.springframework.beans.factory.annotation.Autowired;
    import org.springframework.stereotype.Service;

    import java.time.LocalDateTime;
    import java.util.List;
    import java.util.Optional;

    @Service
    public class HarvestService {

        @Autowired
        private HarvestRepository harvestRepository;

        @Autowired
        private FarmerRepository farmerRepository;

        @Autowired
        private HarvestProducer harvestProducer;

        public void saveHarvest(HarvestDto dto) {
            Optional<Farmer> farmerOpt = farmerRepository.findById(dto.getFarmerId());
            if (farmerOpt.isEmpty()) {
                throw new RuntimeException("Farmer not found");
            }

            Harvest harvest = new Harvest();
            harvest.setFarmer(farmerOpt.get());
            harvest.setProducto(dto.getProducto());
            harvest.setToneladas(dto.getToneladas());
            harvest.setEstado("REGISTRADA");
            harvest.setCreadoEn(LocalDateTime.now());

            harvestRepository.save(harvest);

            harvestProducer.sendNuevaCosecha(harvest);
        }

        public List<Harvest> getAllHarvests() {
            return harvestRepository.findAll();
        }

    }
