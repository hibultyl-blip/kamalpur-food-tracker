from kivy.app import App
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.scrollview import ScrollView
from kivy.uix.popup import Popup
from kivy.core.window import Window

Window.clearcolor = (0.96, 0.97, 0.95, 1)


class KamalpurFoodTracker(App):

    def build(self):
        self.title = "Kamalpur Food Tracker"
        self.cart = []
        self.current_restaurant = ""
        self.manager = ScreenManager()

        self.create_home()
        self.create_restaurants()
        self.create_menu()
        self.create_cart()
        self.create_checkout()
        self.create_tracking()
        self.create_support()
        self.create_registration()
        self.create_dashboard()
        self.create_account().     
        self.go("home")        
        return self.manager

    def customer_care(self, instance):
        from kivy.utils import platform
        if platform == "android":
            from jnius import autoclass

            Intent = autoclass("android.content.Intent")
            Uri = autoclass("android.net.Uri")
            PythonActivity = autoclass(
                "org.kivy.android.PythonActivity"
            )

            intent = Intent(
                Intent.ACTION_DIAL,
                Uri.parse("tel:8798468426")
            )

        PythonActivity.mActivity.startActivity(intent)        
    def new_page(self, name, title):
        screen = Screen(name=name)
        layout = BoxLayout(
            orientation="vertical",
            padding=15,
            spacing=10
        )

        layout.add_widget(Label(
            text=f"[b]{title}[/b]",
            markup=True,
            font_size=23,
            color=(0.05, 0.2, 0.35, 1),
            size_hint_y=None,
            height=55
        ))

        screen.add_widget(layout)
        self.manager.add_widget(screen)
        return layout

    def add_button(self, layout, text, callback,
                   height=50):
        button = Button(
            text=text,
            size_hint_y=None,
            height=height
        )
        button.bind(on_release=callback)
        layout.add_widget(button)
        return button

    def add_back(self, layout, destination="home"):
        self.add_button(
            layout,
            "Back",
            lambda instance: self.go(destination)
        )

    def go(self, page):
        self.manager.current = page

    def show_message(self, title, message):
        Popup(
            title=title,
            content=Label(
                text=message,
                halign="center",
                valign="middle"
            ),
            size_hint=(0.85, 0.4)
        ).open()

    # PAGE 1: HOME

    def create_home(self):
        layout = self.new_page(
            "home",
            "KAMALPUR FOOD TRACKER"
        )

        layout.add_widget(Label(
            text="Food delivery throughout Tripura",
            color=(0.05, 0.45, 0.45, 1),
            size_hint_y=None,
            height=35
        ))

        area = TextInput(
            hint_text="Enter your delivery area",
            multiline=False,
            size_hint_y=None,
            height=45
        )
        layout.add_widget(area)

        self.add_button(
            layout, "Explore Restaurants",
            lambda instance: self.go("restaurants")
        )

        self.add_button(
            layout, "My Cart",
            lambda instance: self.go("cart")
        )

        self.add_button(
            layout, "Track My Order",
            lambda instance: self.go("tracking")
        )

        self.add_button(
            layout, "Customer Support",
            lambda instance: self.go("support")
        )
        self.add_button(
            layout,
            "Customer Care - Call 8798468426",
            self.customer_care
        )
        self.add_button(
            layout, "Restaurant Registration",
            lambda instance: self.go("registration")
        )

        self.add_button(
            layout, "Restaurant Dashboard",
            lambda instance: self.go("dashboard")
        )

        self.add_button(
            layout, "My Account",
            lambda instance: self.go("account")
        )

        layout.add_widget(Label(
            text="Developer: Sandipan foody",
            size_hint_y=None,
            height=30,
            color=(0.2, 0.2, 0.2, 1)
        ))

    # PAGE 2: RESTAURANTS

    def create_restaurants(self):
        layout = self.new_page(
            "restaurants",
            "Restaurants in Tripura"
        )

        restaurants = [
            "Kamalpur Family Restaurant",
            "Tripura Spice Kitchen",
            "Fresh Bite Cafe",
            "Local Food Corner"
        ]

        for restaurant in restaurants:
            self.add_button(
                layout,
                restaurant,
                lambda instance, name=restaurant:
                    self.open_menu(name),
                height=60
            )

        self.add_back(layout)

    def open_menu(self, restaurant):
        self.current_restaurant = restaurant
        self.go("menu")

    # PAGE 3: FOOD MENU

    def create_menu(self):
        layout = self.new_page("menu", "Food Menu")

        layout.add_widget(Label(
            text="Choose food and add it to your cart",
            size_hint_y=None,
            height=35,
            color=(0.1, 0.3, 0.3, 1)
        ))

        foods = [
            ("Veg Thali", 120),
            ("Paneer Meal", 160),
            ("Chicken Meal", 190),
            ("Fried Rice", 100),
            ("Vegetable Chowmein", 90),
            ("Sandwich", 80)
        ]

        for food, price in foods:
            self.add_button(
                layout,
                f"{food} - Rs. {price} - Add",
                lambda instance, name=food, cost=price:
                    self.add_to_cart(name, cost),
                height=55
            )

        self.add_button(
            layout, "View Cart",
            lambda instance: self.go("cart")
        )

        self.add_back(layout, "restaurants")

    def add_to_cart(self, food, price):
        self.cart.append({
            "food": food,
            "price": price,
            "quantity": 1
        })

        self.show_message(
            "Added to Cart",
            f"{food} added successfully!"
        )

    # PAGE 4: CART

    def create_cart(self):
        layout = self.new_page("cart", "My Cart")

        self.cart_items = Label(
            text="Your cart is empty.",
            color=(0.1, 0.1, 0.1, 1),
            halign="left",
            valign="top",
            size_hint_y=None,
            height=220
        )
        layout.add_widget(self.cart_items)

        self.cart_total = Label(
            text="Total: Rs. 0",
            font_size=19,
            color=(0.05, 0.2, 0.35, 1),
            size_hint_y=None,
            height=40
        )
        layout.add_widget(self.cart_total)

        self.add_button(
            layout, "Refresh Cart",
            lambda instance: self.refresh_cart()
        )

        self.add_button(
            layout, "Proceed to Checkout",
            lambda instance: self.checkout()
        )

        self.add_back(layout, "restaurants")

    def refresh_cart(self):
        if not self.cart:
            self.cart_items.text = "Your cart is empty."
            total = 0
        else:
            lines = []
            for item in self.cart:
                lines.append(
                    f"{item['food']} x {item['quantity']} "
                    f"- Rs. {item['price'] * item['quantity']}"
                )
            self.cart_items.text = "\n".join(lines)
            total = sum(
                item["price"] * item["quantity"]
                for item in self.cart
            )

        self.cart_total.text = f"Total: Rs. {total}"

    # PAGE 5: CHECKOUT

    def create_checkout(self):
        layout = self.new_page("checkout", "Checkout")

        layout.add_widget(Label(
            text="Delivery Address",
            color=(0.05, 0.2, 0.35, 1),
            size_hint_y=None,
            height=30
        ))

        self.address = TextInput(
            hint_text="Enter your full delivery address",
            multiline=True,
            size_hint_y=None,
            height=100
        )
        layout.add_widget(self.address)

        self.add_button(
            layout,
            "Cash on Delivery (Demo)",
            lambda instance: self.show_message(
                "COD",
                "Demo only. Real orders are not connected yet."
            )
        )

        self.add_button(
            layout,
            "Pay Online (Not Connected)",
            lambda instance: self.show_message(
                "Online Payment",
                "A verified payment gateway must be integrated."
            )
        )

        self.add_back(layout, "cart")

    def checkout(self):
        self.refresh_cart()

        if not self.cart:
            self.show_message(
                "Empty Cart",
                "Please add food before checkout."
            )
            return

        self.go("checkout")

    # PAGE 6: TRACKING

    def create_tracking(self):
        layout = self.new_page(
            "tracking",
            "Track Your Order"
        )

        layout.add_widget(Label(
            text=(
                "Order status: Demo screen\n\n"
                "Live delivery tracking is not connected yet.\n\n"
                "GPS, a map service, and a backend are "
                "required for genuine live tracking."
            ),
            color=(0.1, 0.2, 0.3, 1)
        ))

        self.add_back(layout)

    # PAGE 7: CUSTOMER SUPPORT

    def create_support(self):
        layout = self.new_page(
            "support",
            "Customer Support"
        )

        self.support_message = TextInput(
            hint_text="Describe your problem",
            multiline=True,
            size_hint_y=None,
            height=120
        )
        layout.add_widget(self.support_message)

        self.add_button(
            layout,
            "Submit Support Request (Demo)",
            lambda instance: self.show_message(
                "Support",
                "This demo does not send messages to a support team."
            )
        )

        self.add_back(layout)

    # PAGE 8: RESTAURANT REGISTRATION

    def create_registration(self):
        layout = self.new_page(
            "registration",
            "Register Your Restaurant"
        )

        self.restaurant_name = TextInput(
            hint_text="Restaurant name",
            multiline=False,
            size_hint_y=None,
            height=45
        )
        layout.add_widget(self.restaurant_name)

        self.restaurant_address = TextInput(
            hint_text="Restaurant address in Tripura",
            multiline=False,
            size_hint_y=None,
            height=45
        )
        layout.add_widget(self.restaurant_address)

        self.restaurant_phone = TextInput(
            hint_text="Restaurant contact number",
            multiline=False,
            input_filter="int",
            size_hint_y=None,
            height=45
        )
        layout.add_widget(self.restaurant_phone)

        self.add_button(
            layout,
            "Submit Registration (Demo)",
            lambda instance: self.show_message(
                "Registration",
                "This demo does not save registrations. "
                "A secure backend and verification are needed."
            )
        )

        self.add_back(layout)

    # PAGE 9: RESTAURANT DASHBOARD

    def create_dashboard(self):
        layout = self.new_page(
            "dashboard",
            "Restaurant Dashboard"
        )

        layout.add_widget(Label(
            text=(
                "Restaurant owner tools will be added here:\n\n"
                "- Manage food items and prices\n"
                "- Upload food photos\n"
                "- Accept or reject orders\n"
                "- Update order status\n"
                "- View sales"
            ),
            color=(0.1, 0.2, 0.3, 1)
        ))

        self.add_back(layout)

    # PAGE 10: CUSTOMER ACCOUNT

    def create_account(self):
        layout = self.new_page("account", "My Account")

        layout.add_widget(Label(
            text=(
                "Customer profile and order history\n\n"
                "Account registration and login "
                "will require a secure backend."
            ),
            color=(0.1, 0.2, 0.3, 1)
        ))

        self.add_back(layout)


if __name__ == "__main__":
    KamalpurFoodTracker().run()
