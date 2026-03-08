describe('InsiderOne Careers Page', () => {
    beforeEach(() => {
        cy.on('uncaught:exception', () => {
            return false
        })
    })

    it('should visit careers page and navigate to QA jobs', () => {
        cy.visit('https://insiderone.com/careers/')
        cy.get('#wt-cli-accept-all-btn').click();
        cy.get('#cookie-law-info-bar').should('not.be.visible')

        cy.get('#page-wrapper a.inso-rounded span').click();
        cy.url().should('eq', 'https://insiderone.com/careers/#open-roles')
        
        cy.get('body.page').should(($el) => {
            expect($el).to.have.class('scrolled')
            expect($el).to.have.class('nav-active')
        })
        
        cy.get('#navigation').should('have.class', 'colored')
        cy.get('#open-roles a.inso-btn').click();
        cy.get('#open-roles div.insiderone-icon-cards-see-more-div').should('have.class', 'open')
        
        cy.get('#open-roles a.inso-btn').should(($el) => {
            expect($el).to.contain.text('See Less')
            expect($el).to.have.attr('aria-expanded', 'true')
        })
        
        cy.wait(5000)
        cy.get('#open-roles a[href="https://jobs.lever.co/insiderone?team=Quality%20Assurance"]').click();

        // Farklı origin'e geçiş
        cy.origin('https://jobs.lever.co', () => {
            cy.url().should('eq', 'https://jobs.lever.co/insiderone?team=Quality%20Assurance')
            cy.title().should('eq', 'Insider One')
        })

        cy.visit('https://jobs.lever.co/insiderone?team=Quality%20Assurance')

        cy.origin('https://jobs.lever.co', () => {
            // Cookie banner kontrolü
            cy.get('body').then(($body) => {
                if ($body.find('div.cc-desktop button.button').length > 0) {
                    cy.get('div.cc-desktop button.button').click();
                    cy.get('div.cc-window')
                        .should('not.be.visible')
                        .and('have.class', 'cc-invisible')
                        .and('have.attr', 'style', 'display: none;')
                }
            })

            // Location filter
            cy.get('div[aria-label="Filter by Location: All"] div.filter-button').click();
            cy.get('div[aria-label="Filter by Location: All"]').should('have.attr', 'aria-expanded', 'true')
            cy.get('div[aria-label="Filter by Location: All"] div.filter-popup').should('be.visible')
            
            cy.get('a[href="?team=Quality%20Assurance&location=Istanbul%2C%20Turkiye"]').click();
            cy.url().should('eq', 'https://jobs.lever.co/insiderone?team=Quality%20Assurance&location=Istanbul%2C%20Turkiye')
            
            cy.get('div[aria-label="Filter by Location: Istanbul, Turkiye"] div.filter-button')
                .should('contain.text', 'Istanbul, Turkiye')

            // Team filter
            cy.get('div[aria-label="Filter by Team: Quality Assurance"] div.filter-button svg.icon').click();
            cy.get('div[aria-label="Filter by Team: Quality Assurance"]').should('have.attr', 'aria-expanded', 'true')
            cy.get('li:nth-child(11) a.selected').click();
            cy.get('div[aria-label="Filter by Team: Quality Assurance"] div.filter-popup').should('not.be.visible')

            // Job listings kontrolü
            cy.get('.posting-title').invoke('removeAttr', 'target')
            
            cy.get('.posting').its('length').then((count) => {
                for (let i = 0; i < count; i++) {
                    cy.get('.posting').eq(i).find('.posting-title').click()
                    
                    cy.url().should('include', 'lever.co')
                    cy.get('div.location').should('contain.text', 'Istanbul, Turkiye')
                    cy.get('div.department').should('contain.text', 'Quality Assurance /')
                    cy.get('div.workplaceTypes').should('contain.text', 'Remote')
                    
                    cy.go('back')
                }
            })
        })
    })
})
