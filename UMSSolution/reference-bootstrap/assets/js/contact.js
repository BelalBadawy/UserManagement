$(document).ready(function(){
    
    (function($) {
        "use strict";

    
    jQuery.validator.addMethod('answercheck', function (value, element) {
        return this.optional(element) || /^\bcat\b$/.test(value)
    }, "type the correct answer -_-");

    // validate contactForm form
    $(function() {
        $('#contactForm').validate({
            rules: {
                name: {
                    required: true,
                    minlength: 2
                },
                subject: {
                    required: true,
                    minlength: 4
                },
                number: {
                    required: true,
                    minlength: 5
                },
                email: {
                    required: true,
                    email: true
                },
                message: {
                    required: true,
                    minlength: 20
                }
            },
            messages: {
                name: {
                    required: "come on, you have a name, don't you?",
                    minlength: "your name must consist of at least 2 characters"
                },
                subject: {
                    required: "come on, you have a subject, don't you?",
                    minlength: "your subject must consist of at least 4 characters"
                },
                number: {
                    required: "come on, you have a subject, don't you?",
                    minlength: "your Number must consist of at least 5 characters"
                },
                email: {
                    required: "no email, no message"
                },
                message: {
                    required: "um...yea, you have to write something to send this form.",
                    minlength: "thats all? really?"
                }
            },
            submitHandler: function(form) {
                function hideAllBootstrapModals() {
                    if (!(window.bootstrap && window.bootstrap.Modal)) return;
                    document.querySelectorAll('.modal').forEach(function (modalEl) {
                        if (window.bootstrap.Modal.getOrCreateInstance) {
                            window.bootstrap.Modal.getOrCreateInstance(modalEl).hide();
                        } else {
                            // Back-compat for older Bootstrap 5 builds
                            try { new window.bootstrap.Modal(modalEl).hide(); } catch (e) {}
                        }
                    });
                }

                function showBootstrapModalById(id) {
                    if (!(window.bootstrap && window.bootstrap.Modal)) return;
                    var modalEl = document.getElementById(id);
                    if (!modalEl) return;
                    if (window.bootstrap.Modal.getOrCreateInstance) {
                        window.bootstrap.Modal.getOrCreateInstance(modalEl).show();
                    } else {
                        // Back-compat for older Bootstrap 5 builds
                        try { new window.bootstrap.Modal(modalEl).show(); } catch (e) {}
                    }
                }

                $(form).ajaxSubmit({
                    type:"POST",
                    data: $(form).serialize(),
                    url:"contact_process.php",
                    success: function() {
                        $('#contactForm :input').attr('disabled', 'disabled');
                        $('#contactForm').fadeTo( "slow", 1, function() {
                            $(this).find(':input').attr('disabled', 'disabled');
                            $(this).find('label').css('cursor','default');
                            $('#success').fadeIn()
                            hideAllBootstrapModals();
		                	showBootstrapModalById('success');
                        })
                    },
                    error: function() {
                        $('#contactForm').fadeTo( "slow", 1, function() {
                            $('#error').fadeIn()
                            hideAllBootstrapModals();
		                	showBootstrapModalById('error');
                        })
                    }
                })
            }
        })
    })
        
 })(jQuery)
})