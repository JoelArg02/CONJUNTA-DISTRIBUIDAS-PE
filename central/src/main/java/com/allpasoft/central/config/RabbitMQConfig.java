package com.allpasoft.central.config;

import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    @Bean
    public Queue nuevaCosechaQueue() {
        return QueueBuilder.durable("central.cosechas").build();
    }
}