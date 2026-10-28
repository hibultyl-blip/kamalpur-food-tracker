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

                 
        
            
