import { LocationData } from "@/types/location";
import { openSettings } from "expo-linking";
import * as Location from "expo-location";
import { cssInterop } from "nativewind";
import { FC, useEffect, useState } from "react";
import { Alert, Platform, Text, View } from "react-native";
import MapView, { Details, Region } from "react-native-maps";

cssInterop(MapView, { className: { target: "style" } });

const DEFAULT_DELTA = {
  latitudeDelta: 0.025,
  longitudeDelta: 0.0125,
};

const MIN_DELTA = {
  latitudeDelta: 1,
  longitudeDelta: 1,
};

interface Props {
  location: LocationData;
  onLocationChange: (location: LocationData | null) => void;
}

export const LocationView: FC<Props> = ({ location, onLocationChange }) => {
  const [region, setRegion] = useState<Region>();
  const [neighbourhood, setNeighbourhood] = useState("");

  useEffect(() => {
    if (
      location?.latitude &&
      location?.longitude &&
      location?.neighbourhood
    ) {
      setRegion({
        latitude: location.latitude,
        longitude: location.longitude,
        ...DEFAULT_DELTA,
      });
      setNeighbourhood(location.neighbourhood);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onRegionChangeComplete = async (region: Region, details: Details) => {
    if (Platform.OS === "android" && !details.isGesture) {
      return;
    }

    if (
      region.latitudeDelta > MIN_DELTA.latitudeDelta ||
      region.longitudeDelta > MIN_DELTA.longitudeDelta
    ) {
      setNeighbourhood("Zoom into your neighbourhood");
      onLocationChange(null);
      return;
    }

    try {
      const location = await Location.reverseGeocodeAsync({
        latitude: region.latitude,
        longitude: region.longitude,
      });

      const address = location[0];
      let neighbourhood = "";

      if (address.city) {
        neighbourhood = address.city;
      } else if (address.subregion) {
        neighbourhood = address.subregion;
      } else if (address.region) {
        neighbourhood = address.region;
      } else {
        neighbourhood = "Invalid location";
        setNeighbourhood(neighbourhood);
        onLocationChange(null);
        return;
      }

      setNeighbourhood(neighbourhood);
      onLocationChange({
        latitude: region.latitude,
        longitude: region.longitude,
        neighbourhood: neighbourhood,
      });
    } catch (error: any) {
      switch (error.code) {
        case "E_RATE_EXCEEDED":
          Alert.alert("Error", "Too many requests. Please try again later;");
          break;
        case "ERR_LOCATION_UNAUTHORIZED":
          getPermissions();
          break;
        default:
          Alert.alert("Error", "Something went wrong. Please try again later;");
          break;
      }
    }
  };

  const getPermissions = async () => {
    const { status: existingStatus } =
      await Location.getForegroundPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== "granted") {
      const { status } = await Location.requestForegroundPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== "granted") {
      Alert.alert(
        "Allow Location Access",
        "Please enable Location Services so we can introduce you to new people near you.",
        [
          {
            text: "Cancel",
          },
          {
            text: "Settings",
            onPress: () => {
              openSettings();
            },
          },
        ]
      );
      return;
    }
  };

  return (
    <View className="w-full h-3/5 justify-center items-center">
      <MapView
        className="w-full h-full"
        initialRegion={region}
        region={region}
        onRegionChangeComplete={onRegionChangeComplete}
      />
      <View
        className="bg-black absolute py-2 px-4 rounded-md"
        pointerEvents="none"
      >
        <Text className="text-white text-base font-poppins-regular">
          {neighbourhood}
        </Text>
      </View>
    </View>
  );
};
