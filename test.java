class Ship {
    private String name;
    private int yearBuilt;
    private int year = 2100;

    public Ship(String name, int yearBuilt) {
        this.name = name;
        this.yearBuilt = yearBuilt;
    }

    public String getName() {
        return name;
    }
}