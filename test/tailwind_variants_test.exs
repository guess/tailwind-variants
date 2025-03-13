defmodule TailwindVariantsTest do
  use ExUnit.Case
  doctest TailwindVariants, import: true

  import TailwindVariants
  import TailwindVariants.TestAssertions

  describe "tv/1 - basic component creation" do
    test "creates a simple component with base classes" do
      component = tv(%{base: "font-medium text-lg"})
      assert is_map(component)
      assert component.base == "font-medium text-lg"
    end

    test "creates a component with variants" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            },
            size: %{
              sm: "text-sm",
              lg: "text-lg"
            }
          }
        })

      assert is_map(component)
      assert component.base == "font-medium"
      assert component.variants.color.primary == "text-blue-500"
      assert component.variants.size.sm == "text-sm"
    end

    test "creates a component with default variants" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            }
          },
          default_variants: %{
            color: "primary"
          }
        })

      assert is_map(component)
      assert component.default_variants.color == "primary"
    end

    test "handles nil, empty strings, and undefined values gracefully" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              # Empty variant
              secondary: ""
            },
            size: %{
              # Nil variant
              sm: nil,
              md: "text-base"
            }
          }
        })

      # Should ignore empty variant
      secondary_classes = tw(component, %{color: "secondary"})
      assert_classes_match("font-medium", secondary_classes)

      # Should ignore nil variant
      sm_classes = tw(component, %{size: "sm"})
      assert_classes_match("font-medium", sm_classes)

      # Non-existent variant value
      nonexistent_classes = tw(component, %{color: "nonexistent"})
      assert_classes_match("font-medium", nonexistent_classes)
    end
  end

  describe "tw/2 - basic class generation" do
    test "returns base classes when no variants are provided" do
      component = tv(%{base: "font-medium text-lg"})
      classes = tw(component)
      assert_classes_match("font-medium text-lg", classes)
    end

    test "merges base classes with variant classes" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            }
          }
        })

      classes = tw(component, %{color: "primary"})
      assert_classes_match("font-medium text-blue-500", classes)
    end

    test "applies default variants when no variant props are provided" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            }
          },
          default_variants: %{
            color: "primary"
          }
        })

      classes = tw(component)
      assert_classes_match("font-medium text-blue-500", classes)
    end

    test "variant props override default variants" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            }
          },
          default_variants: %{
            color: "primary"
          }
        })

      classes = tw(component, %{color: "secondary"})
      assert_classes_match("font-medium text-purple-500", classes)
    end

    test "handles boolean variants" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            disabled: %{
              true: "opacity-50 cursor-not-allowed"
            }
          }
        })

      classes = tw(component, %{disabled: true})
      assert_classes_match("font-medium opacity-50 cursor-not-allowed", classes)
    end
  end

  describe "tw/2 - conflict resolution" do
    test "resolves conflicting Tailwind classes using tw_merge" do
      component =
        tv(%{
          base: "p-4 text-red-500",
          variants: %{
            size: %{
              lg: "p-6 text-lg"
            }
          }
        })

      classes = tw(component, %{size: "lg"})
      # p-6 should override p-4
      assert_classes_match("text-red-500 p-6 text-lg", classes)
    end

    test "can disable tw_merge through config" do
      component =
        tv(%{
          base: "p-4 text-red-500",
          variants: %{
            size: %{
              lg: "p-6 text-lg"
            }
          },
          config: %{
            tw_merge: false
          }
        })

      classes = tw(component, %{size: "lg"})
      # Should just concatenate classes without merging
      assert_classes_match("p-4 text-red-500 p-6 text-lg", classes)
    end
  end

  describe "tw/2 - compound variants" do
    test "applies compound variants when multiple conditions match" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            },
            size: %{
              sm: "text-sm",
              lg: "text-lg"
            }
          },
          compound_variants: [
            %{
              color: "primary",
              size: "lg",
              class: "uppercase tracking-wider"
            }
          ]
        })

      classes = tw(component, %{color: "primary", size: "lg"})
      assert_classes_match("font-medium text-blue-500 text-lg uppercase tracking-wider", classes)
    end

    test "handles compound variants with array matching" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500",
              success: "text-green-500"
            }
          },
          compound_variants: [
            %{
              color: ["primary", "secondary"],
              class: "rounded-full"
            }
          ]
        })

      classes_primary = tw(component, %{color: "primary"})
      assert_classes_match("font-medium text-blue-500 rounded-full", classes_primary)

      classes_secondary = tw(component, %{color: "secondary"})
      assert_classes_match("font-medium text-purple-500 rounded-full", classes_secondary)

      classes_success = tw(component, %{color: "success"})
      assert_classes_match("font-medium text-green-500", classes_success)
    end

    test "handles multiple matching compound variants with correct precedence" do
      component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            },
            size: %{
              sm: "text-sm",
              md: "text-base"
            },
            rounded: %{
              true: "rounded-full",
              false: "rounded-none"
            }
          },
          compound_variants: [
            %{
              color: "primary",
              class: "uppercase"
            },
            %{
              color: "primary",
              size: "sm",
              # Should apply with the previous one
              class: "tracking-wide bg-black"
            },
            %{
              color: "primary",
              size: "sm",
              rounded: true,
              # Should apply with the previous ones
              class: "font-bold bg-white"
            }
          ]
        })

      classes = tw(component, %{color: "primary", size: "sm", rounded: true})

      assert_classes_match(
        "text-blue-500 text-sm rounded-full uppercase tracking-wide font-bold bg-white",
        classes
      )
    end
  end

  describe "tw/2 - class overriding" do
    test "allows overriding classes with the class prop" do
      component =
        tv(%{
          base: "font-medium text-blue-500",
          variants: %{
            size: %{
              sm: "text-sm",
              lg: "text-lg"
            }
          }
        })

      classes = tw(component, %{size: "lg", class: "text-green-500 font-bold"})
      assert_classes_match("font-bold text-green-500 text-lg", classes)
    end
  end

  describe "tw/2 - slots" do
    test "returns a map of slot functions" do
      component =
        tv(%{
          slots: %{
            base: "flex items-center",
            label: "text-sm font-medium",
            icon: "w-5 h-5 mr-2"
          }
        })

      slots = tw(component)
      assert is_map(slots)
      assert is_function(slots.base)
      assert is_function(slots.label)
      assert is_function(slots.icon)

      assert_classes_match("flex items-center", tw(slots.base))
      assert_classes_match("text-sm font-medium", tw(slots.label))
      assert_classes_match("w-5 h-5 mr-2", tw(slots.icon))
    end

    test "applies variants to slots" do
      component =
        tv(%{
          slots: %{
            base: "rounded",
            label: "font-medium"
          },
          variants: %{
            color: %{
              primary: %{
                base: "bg-blue-500",
                label: "text-white"
              },
              secondary: %{
                base: "bg-purple-500",
                label: "text-white"
              }
            },
            size: %{
              sm: %{
                base: "px-2 py-1",
                label: "text-sm"
              },
              lg: %{
                base: "px-4 py-2",
                label: "text-lg"
              }
            }
          }
        })

      slots = tw(component, %{color: "primary", size: "sm"})

      assert_classes_match("rounded bg-blue-500 px-2 py-1", tw(slots.base))
      assert_classes_match("font-medium text-white text-sm", tw(slots.label))
    end

    test "applies compound variants to slots" do
      component =
        tv(%{
          slots: %{
            base: "rounded",
            label: "font-medium"
          },
          variants: %{
            color: %{
              primary: %{
                base: "bg-blue-500",
                label: "text-white"
              }
            },
            size: %{
              sm: %{
                base: "p-2",
                label: "text-sm"
              }
            }
          },
          compound_variants: [
            %{
              color: "primary",
              size: "sm",
              class: %{
                base: "border-2 border-blue-700",
                label: "uppercase tracking-wider"
              }
            }
          ]
        })

      slots = tw(component, %{color: "primary", size: "sm"})

      assert_classes_match(
        "rounded bg-blue-500 p-2 border-2 border-blue-700",
        tw(slots.base)
      )

      assert_classes_match(
        "font-medium text-white text-sm uppercase tracking-wider",
        tw(slots.label)
      )
    end

    test "allows overriding slot classes" do
      component =
        tv(%{
          slots: %{
            base: "flex items-center",
            label: "text-sm font-medium"
          }
        })

      slots = tw(component)
      assert_classes_match("flex items-center bg-gray-200", slots.base.(%{class: "bg-gray-200"}))

      assert_classes_match(
        "text-sm font-medium text-red-500",
        slots.label.(%{class: "text-red-500"})
      )
    end

    test "supports compound slots" do
      component =
        tv(%{
          slots: %{
            base: "flex",
            item: "p-2",
            icon: "w-4 h-4"
          },
          compound_slots: [
            %{
              slots: ["item", "icon"],
              class: "text-blue-500"
            }
          ]
        })

      slots = tw(component)
      assert_classes_match("flex", tw(slots.base))
      assert_classes_match("p-2 text-blue-500", tw(slots.item))
      assert_classes_match("w-4 h-4 text-blue-500", tw(slots.icon))
    end

    test "supports compound slots with variants" do
      component =
        tv(%{
          slots: %{
            base: "flex",
            item: "p-2",
            icon: "w-4 h-4"
          },
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            }
          },
          compound_slots: [
            %{
              slots: ["item", "icon"],
              color: "primary",
              class: "font-bold"
            }
          ]
        })

      slots = tw(component, %{color: "primary"})
      assert_classes_match("p-2 text-blue-500 font-bold", tw(slots.item))
      assert_classes_match("w-4 h-4 text-blue-500 font-bold", tw(slots.icon))

      # Should not apply when variant doesn't match
      slots = tw(component, %{color: "secondary"})
      assert_classes_match("p-2 text-purple-500", tw(slots.item))
      assert_classes_match("w-4 h-4 text-purple-500", tw(slots.icon))
    end
  end

  describe "tw/2 - extend" do
    test "merges base classes from extended component" do
      base_component = tv(%{base: "font-medium text-lg"})
      component = tv(%{extend: base_component, base: "text-blue-500 uppercase"})

      classes = tw(component)
      assert_classes_match("font-medium text-lg text-blue-500 uppercase", classes)
    end

    test "merges variants from extended component" do
      base_component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500"
            }
          }
        })

      component =
        tv(%{
          extend: base_component,
          variants: %{
            size: %{
              sm: "text-sm",
              lg: "text-lg"
            }
          }
        })

      classes = tw(component, %{color: "primary", size: "sm"})
      assert_classes_match("font-medium text-blue-500 text-sm", classes)
    end

    test "merges slots from extended component" do
      base_component =
        tv(%{
          slots: %{
            base: "flex items-center",
            label: "font-medium"
          }
        })

      component =
        tv(%{
          extend: base_component,
          slots: %{
            icon: "w-5 h-5 mr-2",
            # Override extended label
            label: "text-sm"
          }
        })

      slots = tw(component)
      assert_classes_match("flex items-center", tw(slots.base))
      assert_classes_match("font-medium text-sm", tw(slots.label))
      assert_classes_match("w-5 h-5 mr-2", tw(slots.icon))
    end

    test "merges compound variants from extended component" do
      base_component =
        tv(%{
          base: "font-medium",
          variants: %{
            color: %{
              primary: "text-blue-500"
            }
          },
          compound_variants: [
            %{
              color: "primary",
              class: "uppercase"
            }
          ]
        })

      component =
        tv(%{
          extend: base_component,
          variants: %{
            size: %{
              sm: "text-sm"
            }
          },
          compound_variants: [
            %{
              size: "sm",
              class: "tracking-wider"
            }
          ]
        })

      classes = tw(component, %{color: "primary", size: "sm"})
      assert_classes_match("font-medium text-blue-500 text-sm uppercase tracking-wider", classes)
    end
  end

  describe "variant_options/1" do
    test "returns all available variants" do
      component =
        tv(%{
          variants: %{
            color: %{
              primary: "text-blue-500",
              secondary: "text-purple-500",
              success: "text-green-500"
            },
            size: %{
              sm: "text-sm",
              md: "text-base",
              lg: "text-lg"
            }
          }
        })

      options = variant_options(component)
      assert is_map(options)
      assert Enum.sort(options.color) == [:primary, :secondary, :success]
      assert Enum.sort(options.size) == [:lg, :md, :sm]
    end
  end
end
