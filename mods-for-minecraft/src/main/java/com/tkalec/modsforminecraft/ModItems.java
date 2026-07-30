package com.tkalec.modsforminecraft;

import net.fabricmc.fabric.api.itemgroup.v1.ItemGroupEvents;
import net.minecraft.item.Item;
import net.minecraft.item.ItemGroups;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.util.Identifier;

public final class ModItems {
	public static final Item RUBY = register("ruby", new Item(new Item.Settings()));

	private static Item register(String name, Item item) {
		return Registry.register(Registries.ITEM, Identifier.of(ModsForMinecraft.MOD_ID, name), item);
	}

	public static void register() {
		ItemGroupEvents.modifyEntriesEvent(ItemGroups.INGREDIENTS)
				.register(entries -> entries.add(RUBY));
	}
}
