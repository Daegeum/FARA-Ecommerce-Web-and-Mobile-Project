// Add 'hovered' class to the selected list item on hover
let listItems = document.querySelectorAll(".navigation li");

function setActiveLink() {
  listItems.forEach(item => {
    item.classList.remove("hovered");
  });
  this.classList.add("hovered");
}

listItems.forEach(item => {
  item.addEventListener("mouseover", setActiveLink);
  item.addEventListener("mouseleave", function () {
    this.classList.remove("hovered"); // Remove 'hovered' when mouse leaves
  });
});

// Menu Toggle for mobile or responsive navigation
let toggle = document.querySelector(".toggle");
let navigation = document.querySelector(".navigation");
let main = document.querySelector(".main");

toggle.addEventListener("click", function () {
  navigation.classList.toggle("active");
  main.classList.toggle("active");
});

