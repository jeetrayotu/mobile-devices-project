# Meet You There!
Karanjot Gaidu, Mihai Magher, Heather Meatherall , Jeet Ray, and Amandeep Saroa

__Meet You There!__ is a [Flutter](https://flutter.dev/) application designed to guide users to a meeting place halfway between them. Users are able to enter 1-2 locations (in the event only one location is entered the app will use the user's current location). A midpoint is then calculated and displayed on the screen, including a highlighted route between the destinations. Users can click on a button to gain more information about the midpoint location.    
![main](https://github.com/user-attachments/assets/4c6a2df4-3bcb-457b-97e6-0e99c1ab85d9) ![midpoint](https://github.com/user-attachments/assets/4fa0ffe8-705b-479d-8795-c077bfc8fafa)

Previously searched locations are stored in a database and users can view these on the history page of the application. From there, users are able to either delete or favourite a location. Favouriting the location stores it in a separated database, which can be viewed via the favourite page of the application. Users are alerted to any changes in the database via notifications and snackbars.
![history](https://github.com/user-attachments/assets/4fd59d9d-45a7-4998-95ee-60e8a535c4a3) ![favourites](https://github.com/user-attachments/assets/cfca977f-9571-4735-bf2a-e012ac0e6ba3)

The settings page allows users to change the app's language. Current offerings include English, Russian, and Hindi.
![setting](https://github.com/user-attachments/assets/4227511b-c413-40cc-a6eb-76b74769e576) ![image](https://github.com/user-attachments/assets/64c4200f-c4b4-4357-887b-4e085b480a45) ![image](https://github.com/user-attachments/assets/f5ef19a0-3fab-4334-936b-c93a046f9e9f)





# API Key
__Meet You There!__ utilizes [openrouteservice](https://openrouteservice.org/). The application comes with a pre-generated api key. In the event this key expires, the following steps outline how to generate your own.
1. Go to https://openrouteservice.org/dev/#/signup
2. Create an account
3. Once logged in, go to the dashboard
4.  Scroll down to _Request a token_. Select _Standard_ for token type and give your token a name. Once this is done, you can select _CREATE TOKEN_  ![createToken](https://github.com/user-attachments/assets/dc1290c0-a494-44b4-a7ac-d961a00b938f)
5. Copy your new key and paste it into line 61 of the _main.dart_ file ![line61](https://github.com/user-attachments/assets/8f423662-1b31-4ae7-a9d6-c7632b1f96b3)

