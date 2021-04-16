# Homework4-F19

This is an app I created during my iOS Fundamentals course, which allows a user to log in to a fake bank account and deposit and withdraw money.

The rest of this README contains word-for-word what I submitted for the original assignment. Essentially, I was asked to explain how the app works in granular detail.

## Summary
The basic workflow of the app is:
1. User enters their phone number into the Phone Number Text Field, and clicks send, which sends a verification code to their phone number.
2. User enters the verification code, and if correct, it brings them to the Home view.
3. In the Home View, user can update their username, view the amount of money in their accounts, and add new accounts.
4. In the Accounts View, user can deposit money into an account, withdraw money from an account, transfer money from one account to another, and delete their account.

## LoginViewController
### Setting up view
Upon `viewDidLoad()`, `initUI()` and `setupKeyboardActions()` are called to set up some final things before the user starts entering their phone number.

`initUI()` customizes a few UI elements that can't be directly set in the storyboard.

`fillFieldWithPreviousPhoneNumber()` will automatically fill in the phone number field with the phone number of the last logged in user. It does this by retrieving the phone number in storage, and formatting the nmber appropriately using PhoneNumberKit's automatic field formatting as well as manual string manipulation.

`setupKeyboardActions()` configures the view to make it so the keyboard immediately opens up upon loading the view, and to make it so the keyboard is immediately dismissed whenever the user taps somewhere on the screen.

### Validating Input
When the user clicks `Send` to validate their phone number, `sendTapped()` is called.

`sendTapped()` first removes the symbols that had been used for formatting the number as the user typed it in. Then, it checks that the the phone number is valid.
- If the number is valid, it uses PhoneNumberKit to convert the number into E164 format and store it in data member `phoneNumber`. If this conversion fails and thus raises an exception, we catch it in the `catch` block and let the user know they have entered an invalid phone number.
- Finally, we call `switchViews()` to switch to either the Verification View or Home View.

`switchViews()` switches to either the Verification View or Home View.
- If a user has previous logged in and the phone number being sent matches the phone number of the previously logged in user, then we call `goToHomeView()`. If not:
 - Next we make API call `sendVerificationCode()` to send the verification code. During the API call, we initiate the Activity Indicator and disable user input to our view to let the user know we are working on sending their code.
 - In the API call, we provide it with a closure to be called once the API call has completed. This closure will display an error message to the screen if it fails to send the code, but if everything goes well it will proceed to the `VerificationViewController`.
 
 `goToHomeView()` segue ways to the Home View.
 
 `goToVerificationView()` segue ways to the Verification View.

`prepare()` is a function we override in order tell Swift to pass in the `phoneNumber` as a data member to the VerificationViewController when we call `performSegue()`.

## VerificationViewController
### Setting up view
Upon `viewDidLoad()`, several functions are called to set up the user interface as well as intialize the view's data structures.

`unwrapAndSortVerificationCodeFieldsOptional()` unwraps our array of verification code fields and places it into a new variable `verificationCodeFields`. Then, it sorts the fields by the order they are displayed to the user. This way, it will make it easier to access and change this array of fields later on.

`disableTextFieldsBesidesFirstOne()` makes sure that the user can only enter the verification code starting in the first text field.

`setupTextFieldDelegates()` makes the delegate for every text field in verificationCodeFields the current class (VerificationViewController).

`initUI()` customizes a few UI elements that couldn't be set in the storyboard.

`setupKeyboardActions()` configures the view to open up the keyboard right away so that the user can start typing the verification code, and to dismiss the keyboard when the user taps anywhere on the screen.

`dismissKeyboard() `will dismiss the keyboard for whatever text field is currently accepting input.

### Interacting with User Input
`onDigitEntry()` is called when when the user has entered a digit into one of the verification fields. If there are still more digits to enter, it moves the cursor to the next field using `switchToFieldWith()`. If there are no more digits to enter, it calls `checkVerificationCode()`.

`switchToFieldWith()` disables the current field, enables and clears the field to switch to, and moves the cursor to that new field.

`checkVerificationCode()` verifies that the verification code entered is correct.
 - First, it combines the separate digits from each field into one string.
 - Next we make the API call `verifyCode()` to verify the code is correct. During the API call, we initiate the Activity Indicator and disable user input to our view to let the user know we are working on verifying their code.
 - In the the API call, we provide it with a closure to be called once the API call has completed. This closure will display an error message to the screen if it was unable to verify the code, and then it will allow the user to try entering again. If everything goes well, however, it will store the phone number and authToken in Storage and then proceed to the `HomeViewController`.

`clearFields()` allows the user to start entering the verification code from the beginning. It achieves this by clearing all the fields, enabling only the first field, and placing the cursor at that first field so the user can being typing there.

`goToHomeView()` segue ways to the Home View.

`resend()` resends the verification code to the user's phone number.
- Just like in LoginViewController, we make the API call `sendVerificationCode()` to send the verification code. During the API call, we initiate the Activity Indicator and disable user input to our view to let the user know we are working on sending their code.
- In the API call, we provide it with a closure to be called once the API call has completed. This closure will display an error message to the screen if it fails to send the code, but if everything goes well it will tell the user that it resent the verification code successfully, and then allow the user to start entering the verification code from the beginnning.

### PinTextField Protocol Implementation
`didPressBackspace()` is the implementation of the PinTextField protocol; it is invoked whenever the user hits backspace, and it causes the cursor to move to the previous field.

## HomeViewController
### Setting up view
`viewDidLoad()` sets the current class to be the dataSource and delegate for the accounts Table View. It also calls `getUserInfoIntoView()` to retrieve the data for the current user, and display that data throughout the HomeViewController.

`displayUsername()` displays the username, or it may display the phone number if no username was previously entered.

`setupPopup()` sets up the appearance of the New Account popup, specifically the shadow around the popup and its rounded edges.

`setPlaceholderText()` generates a unique account name, and sets this new account name as the placeholder text for the the `newAccountField` in the `newAccountPopup`, which is the field where the user enters their new account name.

### Interacting with User Input
`onUpdateUserName()` is called after the user finishes updating their username. It sends the api call `setName()` in order to update the username on the server.

`onTapAnywhere()` is called when the user clicks anywhere in the view. It sets up the delegate to define when UIGestureRecognizer should react to a touch. If the delegate determines it should react to the touch, it simply closes the keyboard.

`onAddAccount()` displays the `newAccountPopup` and opens up the keyboard to start typing a new account name.

`onDone()` is called when the user click `Done` in the `newAccountPopup`. It grabs the entered new account name (or the default placeholder name if the user didn't enter anything), and then makes the API call to add the new account. Then, it hides the `newAccountPopup` and updates the view with the newly entered account.

`onLogout()` is called when the user clicks the button to logout. It calls `goToLoginView()`.

`goToLoginView()` segue ways to the Navigation Controller, which in turn displays the LoginViewController.

### Delegate and Data Source Implementations
`accountsUpdated()` implements the delegate for the UpdateHomeViewController protocol. This way, whenever the AccountsView makes an API call to change funds in user accounts, it can call this delegate function to update the HomeView to reflect these changes.

`gestureRecognizer()` implements the delegate for the UIGestureRecognizer. It is makes sure that we only call on the UIGestureRecognizer to react to taps if the taps occur in the HomeView (not the `newAccountPopup` view).

`tableView()` implements a data source method of the `accountsTable` view. It returns the number of rows to display in the table view, which we set to be the number of accounts the user has.

`tableView()` implements a data source method of the `accountsTable` view. It retrieves the appropriate account information from our wallet for each cell in the `accountsTable` view.

`tableView()` implements a delegate method of the `accountsTable` view. Whenever the user selects an account in the table, this function switches to the AccountView with the account information corresponding to that account.

`goToAccountView()` switches to the AccountView. It instantiates an AccountViewController, passes in the appropriate account information, and presents the new view.

## AccountViewController
### Setting up view
`viewDidLoad()` displays the account information passed in from the HomeViewController, and formats the appearance of the transaction buttons. Then it sets up the `transferPopup` through calling `setupPopup()`.

`setupPopup()` sets up the appearance of the `transferPopup`, specifically the shadow around the popup and its rounded edges. Then it sets the internals of the popup, that is, the appearance and text of the picker, textfield, and buttons,  as well as the delegate and datasource of the picker.

### Interacting with User Input
`onDone()` dismisses the AccountView and goes back to the HomeView upon clicking the `doneButton`.

`onDeposit()` is called when the user presses the `depositButton`. It sets up the UIAlertController for handling deposits into the current account. It sets up the title, text field, and done button, and then presents the alert. The done button is configured to call a handler to retrieve the amount to deposit from the text field, call `Api.deposit()` to deposit the money, and then reflect the change in the account balance in the current Account View as well as in the Home View.

`onWithdraw()` is called when the user presses the `withdrawButton`. It sets up the UIAlertController for handling withdrawls from the current account. It sets up the title, text field, and done button, and then presents the alert. The done button is configured to call a handler to retrieve the amount to withdraw from the text field (making sure it is not more than the current account balance). Then, it calls `Api.withdraw()` to withdraw the money and reflects the change in the account balance in the current Account View as well as in the Home View.

`onTransfer()` is called when the user presses the `transferButton`. It displays the custom `transferPopup`.

`onTransferDone()` is called when the user finishes inputting an amount to transfer and which account to transfer to. It retrieves the amount to transfer from the text field (making sure it is not more than the current account balance), and retrieves the index of the appropriate account to transfer to based on the what he user selected in the `accountPicker`. Then, it calls `Api.transfer()` to transfer the money and reflects the change in the account balance in the current Account View as well as in the Home View. Finally, it hides the popup and returns to the AccountView.

`onDelete()` is called when the user presses the `deleteButton`. It calls `Api.delete()` to delete the account, reflects the change by removing the account from the HomeView, and returns back to the HomeView.

### Delegate and Data Source Implementations for PickerView
`numberOfComponents()` implements a data source method of the `accountPicker`. It returns the number of picker components we want to display in the picker, which we set to be 1.

`pickerView()` implements a data source method of the `accountPicker`. It returns the number of rows we want to include in our `accountPicker`, which we set to be the number of accounts in our `pickerOptions` array.

`pickerView()` implements a delegate method of the `accountPicker`. It retrieves all accounts in `pickerOptions` and displays the appropriate information about each account in the rows of the `accountPicker`.
