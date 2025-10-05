import os
from playwright.sync_api import sync_playwright, expect, Page

def verify_acl_policy_generator(page: Page):
    """
    Verifies the ACL policy generator by testing the dynamic dropdown menus
    for the 'application' and 'project' contexts.
    Uses robust assertions that check for presence in the DOM rather than visibility.
    """
    # Le chemin absolu vers le fichier index.html
    file_path = os.path.abspath('aclpolicy/index.html')
    page.goto(f'file://{file_path}')

    # --- Test 1: Contexte 'application' ---
    print("Test du contexte 'application'...")

    # Changer le contexte en 'application'
    page.get_by_label("Description").click()
    page.locator('select[x-model="policy.context.type"]').select_option('application')

    # Ajouter une règle de ressource
    page.get_by_role("button", name="Ajouter une ressource").click()

    # Vérifier que les options spécifiques à l'application existent dans le DOM
    resource_dropdown_app = page.locator('select[x-model="resourceRule.type"]')
    expect(resource_dropdown_app.locator("option[value='project']")).to_have_text('project')
    expect(resource_dropdown_app.locator("option[value='storage']")).to_have_text('storage')

    # Cliquer pour prendre une capture d'écran pertinente
    resource_dropdown_app.click()
    page.screenshot(path="jules-scratch/verification/01_application_resource_types.png")
    print("Screenshot 1: Types de ressources pour 'application' capturé.")

    # Sélectionner 'storage' et vérifier les propriétés suggérées
    resource_dropdown_app.select_option('storage')
    property_input_app = page.locator('input[x-model="rule.property"]')
    property_input_app.click()

    # Vérifier que les suggestions de propriétés pour 'storage' existent dans le DOM
    expect(page.locator("datalist[id^='datalist-properties-'] option[value='path']")).to_have_attribute('value', 'path')
    expect(page.locator("datalist[id^='datalist-properties-'] option[value='name']")).to_have_attribute('value', 'name')

    page.screenshot(path="jules-scratch/verification/02_application_storage_properties.png")
    print("Screenshot 2: Propriétés pour 'application:storage' capturées.")

    # --- Test 2: Contexte 'project' ---
    print("\nTest du contexte 'project'...")
    page.reload()

    # Ajouter une règle de ressource (le contexte par défaut est 'project')
    page.get_by_role("button", name="Ajouter une ressource").click()

    # Sélectionner le type de ressource 'job'
    resource_dropdown_proj = page.locator('select[x-model="resourceRule.type"]')
    resource_dropdown_proj.select_option('job')

    # Cliquer sur le champ des actions pour révéler les suggestions
    actions_input_proj = page.locator('input[x-model="rule.actions.allow"]')
    actions_input_proj.click()

    # Vérifier que les suggestions d'actions pour 'job' existent dans le DOM
    expect(page.locator("datalist[id^='datalist-actions-'] option[value='run']")).to_have_attribute('value', 'run')
    expect(page.locator("datalist[id^='datalist-actions-'] option[value='kill']")).to_have_attribute('value', 'kill')
    expect(page.locator("datalist[id^='datalist-actions-'] option[value='view_history']")).to_have_attribute('value', 'view_history')

    page.screenshot(path="jules-scratch/verification/03_project_job_actions.png")
    print("Screenshot 3: Actions pour 'project:job' capturées.")

    print("\nVérification terminée avec succès.")

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        verify_acl_policy_generator(page)
        browser.close()

if __name__ == "__main__":
    main()