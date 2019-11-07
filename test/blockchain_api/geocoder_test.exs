defmodule BlockchainAPI.GeocoderTest do
  use BlockchainAPI.DataCase
  alias BlockchainAPI.Geocoder
  import BlockchainAPI.TestHelpers

  @manhattan_results Jason.decode!(~s(
    [
      {
         "address_components" : [
            {
               "long_name" : "130",
               "short_name" : "130",
               "types" : [ "street_number" ]
            },
            {
               "long_name" : "East 18th Street",
               "short_name" : "E 18th St",
               "types" : [ "route" ]
            },
            {
               "long_name" : "Manhattan",
               "short_name" : "Manhattan",
               "types" : [ "political", "sublocality", "sublocality_level_1" ]
            },
            {
               "long_name" : "New York",
               "short_name" : "New York",
               "types" : [ "locality", "political" ]
            },
            {
               "long_name" : "New York County",
               "short_name" : "New York County",
               "types" : [ "administrative_area_level_2", "political" ]
            },
            {
               "long_name" : "New York",
               "short_name" : "NY",
               "types" : [ "administrative_area_level_1", "political" ]
            },
            {
               "long_name" : "United States",
               "short_name" : "US",
               "types" : [ "country", "political" ]
            },
            {
               "long_name" : "10003",
               "short_name" : "10003",
               "types" : [ "postal_code" ]
            }
         ],
         "formatted_address" : "130 E 18th St, New York, NY 10003, USA",
         "geometry" : {
            "bounds" : {
               "northeast" : {
                  "lat" : 40.73632870000001,
                  "lng" : -73.98627680000001
               },
               "southwest" : {
                  "lat" : 40.7359231,
                  "lng" : -73.9870674
               }
            },
            "location" : {
               "lat" : 40.7361064,
               "lng" : -73.9865382
            },
            "location_type" : "ROOFTOP",
            "viewport" : {
               "northeast" : {
                  "lat" : 40.73747488029151,
                  "lng" : -73.98532311970851
               },
               "southwest" : {
                  "lat" : 40.73477691970851,
                  "lng" : -73.98802108029152
               }
            }
         },
         "place_id" : "ChIJWfZX16FZwokR_nYhUNC4Gj8",
         "types" : [ "premise" ]
      }
    ]
  ))

  describe "parse_results under normal conditions" do
    test "parse_results/1 returns a properly parsed map of location data" do
      {:ok, results} = Geocoder.parse_results(@manhattan_results)
      assert results == %{
        long_street: "East 18th Street",
        short_street: "E 18th St",
        long_city: "New York",
        short_city: "New York",
        long_state: "New York",
        short_state: "NY",
        long_country: "United States",
        short_country: "US",
      }
    end
  end

  @brooklyn_results Jason.decode!(~s(
   [
    {
       "address_components" : [
          {
             "long_name" : "802",
             "short_name" : "802",
             "types" : [ "street_number" ]
          },
          {
             "long_name" : "Park Place",
             "short_name" : "Park Pl",
             "types" : [ "route" ]
          },
          {
             "long_name" : "Crown Heights",
             "short_name" : "Crown Heights",
             "types" : [ "neighborhood", "political" ]
          },
          {
             "long_name" : "Brooklyn",
             "short_name" : "Brooklyn",
             "types" : [ "political", "sublocality", "sublocality_level_1" ]
          },
          {
             "long_name" : "Kings County",
             "short_name" : "Kings County",
             "types" : [ "administrative_area_level_2", "political" ]
          },
          {
             "long_name" : "New York",
             "short_name" : "NY",
             "types" : [ "administrative_area_level_1", "political" ]
          },
          {
             "long_name" : "United States",
             "short_name" : "US",
             "types" : [ "country", "political" ]
          },
          {
             "long_name" : "11216",
             "short_name" : "11216",
             "types" : [ "postal_code" ]
          }
       ],
       "formatted_address" : "802 Park Pl, Brooklyn, NY 11216, USA",
       "geometry" : {
          "location" : {
             "lat" : 40.673229,
             "lng" : -73.95115
          },
          "location_type" : "ROOFTOP",
          "viewport" : {
             "northeast" : {
                "lat" : 40.6745779802915,
                "lng" : -73.94980101970849
             },
             "southwest" : {
                "lat" : 40.6718800197085,
                "lng" : -73.95249898029151
             }
          }
       },
       "place_id" : "ChIJHQe5pZ1bwokR27FsUPXmYJY",
       "plus_code" : {
          "compound_code" : "M2FX+7G New York, United States",
          "global_code" : "87G8M2FX+7G"
       },
       "types" : [ "street_address" ]
    }
  ]
  ))

  describe "parse_results under Brooklyn case" do
    test "parse_results/1 returns a properly parsed map of location data" do
      {:ok, results} = Geocoder.parse_results(@brooklyn_results)
      assert results == %{
        long_street: "Park Place",
        short_street: "Park Pl",
        long_city: "Brooklyn",
        short_city: "Brooklyn",
        long_state: "New York",
        short_state: "NY",
        long_country: "United States",
        short_country: "US",
      }
    end
  end
end
