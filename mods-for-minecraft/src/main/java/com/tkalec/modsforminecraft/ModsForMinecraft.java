package com.tkalec.modsforminecraft;

import net.fabricmc.api.ModInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ModsForMinecraft implements ModInitializer {
	public static final String MOD_ID = "modsforminecraft";
	public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

	@Override
	public void onInitialize() {
		ModItems.register();
		LOGGER.info("Mods for Minecraft initialized!");
	}
}
