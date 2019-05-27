package com.redhat.coolstore;

import javax.persistence.Cacheable;
import javax.persistence.Column;
import javax.persistence.Entity;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
@Cacheable
public class Inventory extends PanacheEntity {

	@Column
    public String location;

	@Column
    public int quantity;

	@Column
    public String link;

    public Inventory() {

    }

    public Inventory(Long itemId, int quantity, String location, String link) {
        super();
        this.quantity = quantity;
        this.location = location;
        this.link = link;
    }

}