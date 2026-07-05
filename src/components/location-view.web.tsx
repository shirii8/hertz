import { LocationData } from "@/types/location";
import { FC } from "react";
import { Text, View } from "react-native";

interface Props {
  location: LocationData;
  onLocationChange: (location: LocationData | null) => void;
}

export const LocationView: FC<Props> = ({ location }) => {
  return (
    <View className="w-full h-3/5 justify-center items-center bg-neutral-100 p-5">
      <Text className="text-base font-poppins-medium text-center">
        Map-based location picking isn&apos;t available on web.
      </Text>
      <Text className="text-sm font-poppins-regular text-neutral-500 text-center mt-2">
        {location?.neighbourhood
          ? `Current neighbourhood: ${location.neighbourhood}`
          : "Open the app on your phone to set your location."}
      </Text>
    </View>
  );
};
