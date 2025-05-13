# amboss_automation.py
import random
import time
from faker import Faker
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

def create_amboss_account():
    # === Generate fake user data ===
    fake = Faker()
    first_name = fake.first_name()
    last_name = fake.last_name()
    # Ensure email is somewhat unique and less likely to be flagged
    timestamp = int(time.time())
    email = f"{first_name.lower()}.{last_name.lower()}.{timestamp}{random.randint(100,999)}@gmail.com"
    password = "SecurePassword@123!" # Use a more generic complex password

    # === Chrome options ===
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox") # Essential for running as root in Docker
    options.add_argument("--disable-dev-shm-usage") # Essential for Docker
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920x1080") # Can help with some headless issues

    # IMPORTANT: ChromeDriver path needs to be configured for the server environment (e.g., /usr/bin/chromedriver or use WebDriverManager)
    # For Render with Docker, you'd typically ensure chromedriver is in the PATH
    # and Selenium can find it without specifying an executable_path.
    # Example (if chromedriver is in PATH):
    # service = Service()
    # If you install a specific version of chromedriver in your Docker image:
    service = Service() # Assuming chromedriver is in PATH in your Docker env
    # If you must specify, ensure this path is correct in your Docker image:
    # service = Service(executable_path='/usr/local/bin/chromedriver')


    driver = None # Initialize driver to None for the finally block
    try:
        driver = webdriver.Chrome(service=service, options=options)
        wait = WebDriverWait(driver, 30) # Increased wait time for robustness

        # STEP 1: Open AMBOSS registration
        driver.get("https://next.amboss.com/us/registration")

        # STEP 2: Fill in email and password
        wait.until(EC.presence_of_element_located((By.NAME, "email"))).send_keys(email)
        driver.find_element(By.NAME, "password").send_keys(password)

        # STEP 3: Click "Sign up"
        sign_up_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//div[text()='Sign up']]")))
        driver.execute_script("arguments[0].click();", sign_up_button)

        # STEP 4: Country
        country_input = wait.until(EC.presence_of_element_located((By.XPATH, "//input[@aria-label='Country']")))
        country_input.send_keys("United States of America")
        time.sleep(1) # Keystrokes might need a slight pause
        country_input.send_keys(webdriver.common.keys.Keys.ENTER) # Use Keys.ENTER
        time.sleep(1)

        next_btn = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//div[text()='Next']]")))
        driver.execute_script("arguments[0].click();", next_btn)

        # STEP 5: Select "Medical Student"
        role_div = wait.until(EC.element_to_be_clickable((By.XPATH, "//div[normalize-space(text())='Medical Student']")))
        driver.execute_script("arguments[0].click();", role_div)

        next_btn2 = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//div[text()='Next']]")))
        # wait.until(lambda d: next_btn2.is_enabled() and next_btn2.get_attribute("aria-disabled") != "true") # This lambda might be flaky
        time.sleep(1) # Give it a moment for the button to become truly active
        driver.execute_script("arguments[0].click();", next_btn2)

        # STEP 6: University
        university_input = wait.until(EC.element_to_be_clickable((By.XPATH, "//input[@aria-label='University']")))
        university_input.click()
        time.sleep(0.5)
        university_input.send_keys("Yale School of Medicine")
        time.sleep(1)
        university_input.send_keys(webdriver.common.keys.Keys.ENTER)

        # STEP 7: Expected graduation year
        grad_year_input = wait.until(EC.element_to_be_clickable((By.XPATH, "//input[@aria-label='Expected graduation year']")))
        grad_year_input.click()
        time.sleep(0.5)
        grad_year_input.send_keys("2026")
        time.sleep(1)
        grad_year_input.send_keys(webdriver.common.keys.Keys.ENTER)

        # STEP 8: Current objective
        objective_input = wait.until(EC.element_to_be_clickable((By.XPATH, "//input[@aria-label='Current Objective']")))
        driver.execute_script("arguments[0].click();", objective_input) # Use JS click if regular click is problematic
        time.sleep(0.5)
        objective_input.send_keys("USMLE Step 2 CK")
        time.sleep(1)
        objective_input.send_keys(webdriver.common.keys.Keys.ENTER)

        # STEP 9: Name
        wait.until(EC.presence_of_element_located((By.NAME, "firstName"))).send_keys(first_name)
        driver.find_element(By.NAME, "lastName").send_keys(last_name)

        # STEP 10: Tick required checkboxes
        checkbox_names = ["isBetaTester", "hasConfirmedPhysicianDisclaimer"]
        for name in checkbox_names:
            try:
                # Wait for the checkbox wrapper to be clickable, then click it
                checkbox_wrapper_xpath = f"//input[@name='{name}']/ancestor::label[1]" # More reliable way to find clickable wrapper
                checkbox_wrapper = wait.until(EC.element_to_be_clickable((By.XPATH, checkbox_wrapper_xpath)))
                # Check if already checked via aria-checked on the input itself
                checkbox_input = driver.find_element(By.NAME, name)
                if checkbox_input.get_attribute("aria-checked") != "true":
                    driver.execute_script("arguments[0].click();", checkbox_wrapper) # Use JS click if issues persist
                    time.sleep(0.5) # Increased sleep
            except Exception as e:
                return {"error": f"Could not interact with checkbox '{name}': {e}"}


        # STEP 11: Click "Finish set-up"
        finish_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[.//div[text()='Finish set-up']]")))
        driver.execute_script("arguments[0].click();", finish_button)

        # STEP 12: Handle post-setup flow (Optional, can be simplified or made more robust)
        # This part is prone to failure if the UI changes or loads slowly.
        # For simplicity in returning credentials, we might skip confirming these popups
        # if the account is considered "created" after "Finish set-up".
        # If these steps are crucial, they need careful, robust waits.

        # For now, assume account is created and return credentials
        return {"email": email, "password": password, "status": "Account creation process initiated."}

    except Exception as e:
        # Capture a screenshot on error for debugging in headless mode
        if driver:
            driver.save_screenshot("error_screenshot.png") # This will save in the current working dir of the server
        return {"error": str(e), "email": email, "password": password} # Return generated creds even on error
    finally:
        if driver:
            driver.quit()
