# Tailwind Variants for Elixir

A port of the popular [tailwind-variants](https://www.tailwind-variants.org/) library to Elixir, providing a first-class variant API for TailwindCSS in Elixir applications.

## Features

- First-class variant API
- Slots support
- Composition support
- Automatic conflict resolution
- Compound variants
- Type-safe variants

## Installation

Add `tailwind_variants` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tailwind_variants, "~> 0.1"},
    {:tw_merge, "~> 0.1.1"} # Required for class merging
  ]
end
```

## Usage

### Basic Example

```elixir
import TailwindVariants, only: [tv: 1, class_list: 2]

button = tv(%{
  base: "font-medium bg-blue-500 text-white rounded-full active:opacity-80",
  variants: %{
    color: %{
      primary: "bg-blue-500 text-white",
      secondary: "bg-purple-500 text-white"
    },
    size: %{
      sm: "text-sm",
      md: "text-base",
      lg: "px-4 py-3 text-lg"
    }
  },
  compound_variants: [
    %{
      size: ["sm", "md"],
      class: "px-3 py-1"
    }
  ],
  default_variants: %{
    size: "md",
    color: "primary"
  }
})

# Use in Phoenix/LiveView
<button class={class_list(button, %{size: "sm", color: "secondary"})}>
  Click me
</button>
```

### With Slots

Slots allows you to separate a component into multiple parts.

```elixir
import TailwindVariants, only: [tv: 1, class_list: 2]

card = tv(%{
  slots: %{
    base: "md:flex bg-slate-100 rounded-xl p-8 md:p-0 dark:bg-gray-900",
    avatar: "w-24 h-24 md:w-48 md:h-auto md:rounded-none rounded-full mx-auto drop-shadow-lg",
    wrapper: "flex-1 pt-6 md:p-8 text-center md:text-left space-y-4",
    description: "text-md font-medium",
    info_wrapper: "font-medium",
    name: "text-sm text-sky-500 dark:text-sky-400",
    role: "text-sm text-slate-700 dark:text-slate-500"
  }
})

# Destructure the slots
%{base: base, avatar: avatar, wrapper: wrapper, description: description,
  info_wrapper: info_wrapper, name: name, role: role} = class_list(card, %{})

# Use in Phoenix/LiveView
<figure class={tw(base)}>
  <img class={tw(avatar)} src="/intro-avatar.png" alt="" width="384" height="512" />
  <div class={tw(wrapper)}>
    <blockquote>
      <p class={tw(description)}>
        "Tailwind variants allows you to reduce repeated code in your project
        and make it more readable."
      </p>
    </blockquote>
    <figcaption class={tw(info_wrapper)}>
      <div class={tw(name)}>Zoey Lang</div>
      <div class={tw(role)}>Full-stack developer</div>
    </figcaption>
  </div>
</figure>
```

### Variants with Slots

You can also add variants to components with slots.

```elixir
import TailwindVariants, only: [tv: 1, class_list: 2]

alert = tv(%{
  slots: %{
    root: "rounded py-3 px-5 mb-4",
    title: "font-bold mb-1",
    message: ""
  },
  variants: %{
    variant: %{
      outlined: %{
        root: "border"
      },
      filled: %{
        root: ""
      }
    },
    severity: %{
      error: "",
      success: ""
    }
  },
  compound_variants: [
    %{
      variant: "outlined",
      severity: "error",
      class: %{
        root: "border-red-700 dark:border-red-500",
        title: "text-red-700 dark:text-red-500",
        message: "text-red-600 dark:text-red-500"
      }
    },
    %{
      variant: "outlined",
      severity: "success",
      class: %{
        root: "border-green-700 dark:border-green-500",
        title: "text-green-700 dark:text-green-500",
        message: "text-green-600 dark:text-green-500"
      }
    },
    %{
      variant: "filled",
      severity: "error",
      class: %{
        root: "bg-red-100 dark:bg-red-800",
        title: "text-red-900 dark:text-red-50",
        message: "text-red-700 dark:text-red-200"
      }
    },
    %{
      variant: "filled",
      severity: "success",
      class: %{
        root: "bg-green-100 dark:bg-green-800",
        title: "text-green-900 dark:text-green-50",
        message: "text-green-700 dark:text-green-200"
      }
    }
  ],
  default_variants: %{
    variant: "filled",
    severity: "success"
  }
})

%{root: root, message: message, title: title} = class_list(alert, %{severity: "error", variant: "outlined"})

# Use in Phoenix/LiveView
<div class={tw(root)}>
  <div class={tw(title)}>Oops, something went wrong</div>
  <div class={tw(message)}>
    Something went wrong saving your changes. Try again later.
  </div>
</div>
```

### Component Composition

You can compose components using the `extend` parameter:

```elixir
import TailwindVariants, only: [tv: 1, class_list: 2]

base_button = tv(%{
  base: "font-semibold dark:text-white py-1 px-3 rounded-full active:opacity-80 bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-800 dark:hover:bg-zinc-800"
})

buy_button = tv(%{
  extend: base_button,
  base: "text-sm text-white rounded-lg shadow-lg uppercase tracking-wider bg-blue-500 hover:bg-blue-600 shadow-blue-500/50 dark:bg-blue-500 dark:hover:bg-blue-600"
})

# Use in Phoenix/LiveView
<div class="flex gap-3">
  <button class={class_list(base_button, %{})}>Button</button>
  <button class={class_list(buy_button, %{})}>Buy button</button>
</div>
```

### Compound Slots

You can define styles that apply to specific slots when certain conditions are met:

```elixir
import TailwindVariants, only: [tv: 1, class_list: 2]

button = tv(%{
  slots: %{
    base: "flex items-center",
    icon: "w-4 h-4",
    text: "ml-2"
  },
  variants: %{
    size: %{
      sm: %{
        icon: "w-3 h-3",
        text: "text-xs"
      },
      lg: %{
        icon: "w-5 h-5",
        text: "text-lg"
      }
    }
  },
  compound_slots: [
    %{
      slots: ["icon", "text"],
      size: "lg",
      class: "font-bold" # This will apply to both icon and text slots when size is "lg"
    }
  ]
})

%{base: base, icon: icon, text: text} = class_list(button, %{size: "lg"})

# Use in Phoenix/LiveView
<button class={tw(base)}>
  <svg class={tw(icon)} viewBox="0 0 24 24"><!-- SVG contents --></svg>
  <span class={tw(text)}>Click me</span>
</button>
```

## Configuration

### TwMerge Configuration

If you need to customize the TwMerge behavior, you can pass a configuration in your component:

```elixir
button = tv(%{
  base: "...",
  config: %{
    tw_merge: true, # Set to false to disable TwMerge and use simple joining
  }
})
```

## API Reference

### TailwindVariants.tv/1

Creates a tailwind-variants component:

```elixir
tv(options)
```

#### Parameters

The `options` argument is a map with the following keys:

- `base` (optional): The base styles for the component
- `slots` (optional): A map of slot names to their styles
- `variants` (optional): A map of variant names to their values
- `default_variants` (optional): A map of variant names to their default values
- `compound_variants` (optional): A list of compound variants
- `compound_slots` (optional): A list of compound slots
- `extend` (optional): Another component to extend
- `config` (optional): Configuration options

#### Return Value

Returns a component that can be used with `class_list/2`.

### TailwindVariants.class_list/2

Applies the component with the given props to generate class names:

```elixir
class_list(component, props \\ %{})
```

#### Parameters

- `component`: A component created with `tv/1`
- `props`: A map of props to apply to the component

#### Return Value

Returns either:
- A string of class names (if no slots are defined)
- A map of slot functions (if slots are defined)

### TailwindVariants.tw/2

An alias for `class_list/2` for shorter code:

```elixir
tw(component, props \\ %{})
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

This library is an Elixir port of the JavaScript [tailwind-variants](https://www.tailwind-variants.org/) library created by Junior Garcia (@jrgarciadev) and Tianen Pang (@tianenpang).
