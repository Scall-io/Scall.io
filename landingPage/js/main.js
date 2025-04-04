$(document).ready(function () {
	"use strict"; // start of use strict

	/*==============================
	Mobile navigation
	==============================*/
	$('.header__btn').on('click', function() {
		$(this).toggleClass('header__btn--active');
		$('.header__nav').toggleClass('header__nav--active');

		if ( $(window).scrollTop() == 0 ) {
			$('.header').toggleClass('header--active');
		}
	});

	$('.header__nav a[data-scroll]').on('click', function() {
		$('.header__nav').toggleClass('header__nav--active');
		$('.header__btn').toggleClass('header__btn--active');
	});

	/*==============================
	Header
	==============================*/
	$(window).on('scroll', function () {
		if ( $(window).scrollTop() > 0 ) {
			$('.header').addClass('header--active');
		} else {
			$('.header').removeClass('header--active');
		}
	});
	$(window).trigger('scroll');

	/*==============================
	Home slider
	==============================*/
	$('.home__slider').owlCarousel({
		animateOut: 'fadeOut',
		animateIn: 'fadeIn',
		mouseDrag: false,
		touchDrag: false,
		dots: false,
		items: 1,
		loop: true,
		autoplay: true,
		autoplayTimeout: 4200,
		smartSpeed: 800,
	});

	$('.home__slider .item').each(function(){
		if ($(this).attr("data-bg")){
			$(this).css({
				'background': 'url(' + $(this).data('bg') + ')',
				'background-position': 'center center',
				'background-repeat': 'no-repeat',
				'background-size': 'cover'
			});
		}
	});

	/*==============================
	Section bg
	==============================*/
	$('.section--bg').each(function(){
		if ($(this).attr("data-bg")){
			$(this).css({
				'background': 'url(' + $(this).data('bg') + ')',
				'background-position': 'center center',
				'background-repeat': 'no-repeat',
				'background-size': 'cover'
			});
		}
	});

	/*==============================
	Partners slider
	==============================*/
	$('.partners__slider').owlCarousel({
		mouseDrag: false,
		touchDrag: false,
		dots: false,
		loop: true,
		autoplay: true,
		autoplayTimeout: 5000,
		autoplayHoverPause: true,
		smartSpeed: 700,
		margin: 20,
		responsive : {
			0 : {
				items: 2,
			},
			576 : {
				items: 3,
				margin: 20,
			},
			768 : {
				items: 4,
				margin: 30
			},
			992 : {
				items: 5,
				margin: 30
			},
			1200 : {
				items: 5,
				margin: 50
			}
		}
	});

	/*==============================
	Counter
	==============================*/
	$('.counter__value').counterUp({
		delay: 10,
		time: 800
	});

	/*==============================
	Smooth scroll
	==============================*/
	var scroll = new SmoothScroll('[data-scroll]', {
		ignore: '[data-scroll-ignore]',
		header: '.header',
		speed: 600,
		offset: 0,
		easing: 'easeInOutCubic',
		updateURL: false,
	});

	/*==============================
	Modal
	==============================*/
	$('.video__btn').magnificPopup({
		disableOn: 0,
		type: 'iframe',
		mainClass: 'mfp-fade',
		removalDelay: 300,
		preloader: false,
		fixedContentPos: false
	});

	$('.modal-btn').magnificPopup({
		fixedContentPos: true,
		fixedBgPos: true,
		overflowY: 'auto',
		type: 'inline',
		preloader: false,
		focus: '#username',
		modal: false,
		removalDelay: 300,
		mainClass: 'my-mfp-zoom-in',
		callbacks: {
			open: function() {
				if ($(window).width() > 1200) {
					$('.header').css('margin-left', "-" + (getScrollBarWidth()/2) + "px");
				}
			},
			close: function() {
				if ($(window).width() > 1200) {
					$('.header').css('margin-left', 0);
				}
			}
		}
	});

	$('.modal-article').magnificPopup({
		fixedContentPos: true,
		fixedBgPos: true,
		overflowY: 'auto',
		type: 'inline',
		preloader: false,
		focus: '#username',
		modal: false,
		removalDelay: 300,
		mainClass: 'my-mfp-zoom-in',
		callbacks: {
			open: function() {
				if ($(window).width() > 1200) {
					$('.header').css('margin-left', "-" + (getScrollBarWidth()/2) + "px");
				}
			},
			close: function() {
				if ($(window).width() > 1200) {
					$('.header').css('margin-left', 0);
				}
			}
		}
	});

	$('.modal__close').on('click', function (e) {
		e.preventDefault();
		$.magnificPopup.close();
	});

	function getScrollBarWidth () {
		var $outer = $('<div>').css({visibility: 'hidden', width: 100, overflow: 'scroll'}).appendTo('body'),
			widthWithScroll = $('<div>').css({width: '100%'}).appendTo($outer).outerWidth();
		$outer.remove();
		return 100 - widthWithScroll;
	};

});

var ctx = document.getElementById("tokenchart").getContext('2d');

var myChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
        labels: ['Users', 'Team'],
        datasets: [{
            label: '% of total tokens',
            data: [90, 10],
            backgroundColor: [
                '#2196F3', // Bright Blue
                '#FFC107'  // Bright Yellow
            ],
            borderColor: [
                '#2196F3',
                '#FFC107'
            ],
            borderWidth: 2
        }]
    },
    options: {
        plugins: {
            legend: {
                display: false // Hide default legend
            },
            tooltip: {
                callbacks: {
                    label: function(tooltipItem) {
                        return `${tooltipItem.label}: ${tooltipItem.raw}%`;
                    }
                }
            },
            datalabels: {
                color: 'white',
                font: {
                    weight: 'bold',
                    size: 14
                },
                formatter: (value, ctx) => {
                    let total = ctx.chart.data.datasets[0].data.reduce((acc, val) => acc + val, 0);
                    let percentage = ((value / total) * 100).toFixed(1) + "%";
                    return percentage;
                },
                anchor: 'center',
                align: 'center'
            }
        }
    },
    plugins: [ChartDataLabels] // Ensure Chart.js DataLabels plugin is enabled
});
